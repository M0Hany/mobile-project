import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:http_parser/http_parser.dart';
import '../models/user.dart';

class AuthService {
  final String baseUrl;
  final Logger _logger = Logger();
  User? _currentUser;
  String? _authToken;

  AuthService({required this.baseUrl});

  User? get currentUser => _currentUser;

  String? getLoggedInUsername() {
    return currentUser?.email;
  }

  Future<String?> getStoredToken() async {
    if (_authToken != null) return _authToken;

    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      return _authToken;
    } catch (e) {
      _logger.e('Error getting stored token', error: e);
      return null;
    }
  }

  Future<void> _setStoredToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _authToken = token;
    } catch (e) {
      _logger.e('Error storing token', error: e);
    }
  }

  Future<String?> getStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      _logger.i('Retrieved stored email: $email');
      return email;
    } catch (e) {
      _logger.e('Error getting stored email', error: e);
      return null;
    }
  }

  Future<User?> getUser(String email) async {
    try {
      _logger.i('Getting user data for email: $email');
      _logger.d('Request URL: $baseUrl/api/users/$email');

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$email'),
        headers: {'Content-Type': 'application/json'},
      );

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromMap(data);
        _currentUser = user;
        return user;
      } else {
        final error = jsonDecode(response.body);
        _logger.e('Error response from server', error: error);
        throw Exception(error['message'] ?? 'Failed to get user');
      }
    } catch (e, stackTrace) {
      _logger.e('Error getting user', error: e, stackTrace: stackTrace);
      throw Exception('Failed to get user: $e');
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      _logger.i('Attempting login for email: $email');
      _logger.d('Request URL: $baseUrl/login');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromMap(data['user']);
        _currentUser = user;

        // Store the auth token
        if (data['token'] != null) {
          await _setStoredToken(data['token']);
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', user.email);
          _logger.i('Login successful, stored email in preferences');
        } catch (e) {
          _logger.e('Error storing email in preferences', error: e);
          // Continue even if storage fails
        }

        return user;
      } else {
        final error = jsonDecode(response.body);
        _logger.e('Login failed', error: error);
        throw error['message'] ?? 'Login failed';
      }
    } catch (e, stackTrace) {
      _logger.e('Error during login', error: e, stackTrace: stackTrace);
      throw e.toString();
    }
  }

  Future<User?> register(User user, String password) async {
    try {
      print('AuthService: Preparing registration request');
      print('AuthService: Request URL: $baseUrl/signup');
      print(
        'AuthService: Request body: ${jsonEncode({
              'name': user.name,
              'email': user.email,
              'gender': user.gender,
              'level': user.level,
              'password': password
            })}',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': user.name,
          'email': user.email,
          'gender': user.gender,
          'level': user.level,
          'password': password,
        }),
      );

      print('AuthService: Response status code: ${response.statusCode}');
      print('AuthService: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('AuthService: Registration successful, parsing user data');
        final registeredUser = User.fromMap(data['user']);
        _currentUser = registeredUser;

        // Save user email in secure storage after registration
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', registeredUser.email);

        return registeredUser;
      } else {
        final error = jsonDecode(response.body);
        print(
          'AuthService: Registration failed with status ${response.statusCode}',
        );
        print('AuthService: Error response: $error');
        throw error['message'] ?? 'Registration failed';
      }
    } catch (e, stackTrace) {
      print('AuthService: Exception during registration:');
      print('AuthService: Error type: ${e.runtimeType}');
      print('AuthService: Error message: $e');
      print('AuthService: Stack trace: $stackTrace');
      throw e.toString();
    }
  }

  Future<void> updateUser(User user) async {
    try {
      _logger.i('Updating user profile for email: ${user.email}');

      final request =
          http.MultipartRequest('PUT', Uri.parse('$baseUrl/update-user'))
            ..fields['email'] = user.email
            ..fields['name'] = user.name;

      if (user.gender != null) {
        request.fields['gender'] = user.gender!;
      }

      if (user.level != null) {
        request.fields['level'] = user.level.toString();
      }

      if (user.profilePictureData != null) {
        final profilePic = http.MultipartFile.fromBytes(
          'profile_picture',
          user.profilePictureData!,
          filename: 'profile_picture.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(profilePic);
      }

      _logger.d('Update request fields: ${request.fields}');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response body: $responseData');

      if (response.statusCode != 200) {
        final decodedResponse = json.decode(responseData);
        _logger.e('Update failed', error: decodedResponse);
        throw Exception(decodedResponse['message'] ?? 'Failed to update user');
      }

      final decodedResponse = json.decode(responseData);
      _currentUser = User.fromMap(decodedResponse['user']);
      _logger.i('User profile updated successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Error updating user profile',
        error: e,
        stackTrace: stackTrace,
      );
      throw e.toString();
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('auth_token');
      _currentUser = null;
      _authToken = null;
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error during logout', error: e);
      throw Exception('Failed to logout: $e');
    }
  }

  Future<void> updateProfileDetails({
    required String name,
    required String email,
    String? gender,
    int? level,
    String? password,
  }) async {
    await updateUser(
      User(
        name: name,
        email: email,
        gender: gender,
        level: level,
        password: password,
      ),
    );
  }

  Future<bool> validateOldPassword(String oldPassword) async {
    try {
      _logger.i('Validating old password');
      final email = await getStoredEmail();
      if (email == null) {
        throw Exception('No user email found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': oldPassword}),
      );

      _logger.d('Response status code: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error validating old password', error: e);
      return false;
    }
  }

  // The following methods are stubs for profile picture.
  // You can implement them as needed or remove them if not required.
  Future<Uint8List> getProfilePicture() async {
    throw UnimplementedError();
  }

  Future<void> updateProfilePicture(Uint8List imageBytes) async {
    throw UnimplementedError();
  }
}
