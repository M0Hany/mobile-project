import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import '../models/store.dart';
import 'auth_service.dart';

class StoreService {
  static const String _baseUrl = 'http://10.0.2.2:3000';
  final Logger _logger = Logger();
  final _client = http.Client();
  final AuthService authService;

  // RX Subjects for state management
  final _storesSubject = BehaviorSubject<List<Store>>();
  final _loadingSubject = BehaviorSubject<bool>();
  final _errorSubject = BehaviorSubject<String?>();

  // Exposed streams
  Stream<List<Store>> get stores => _storesSubject.stream;
  Stream<bool> get loading => _loadingSubject.stream;
  Stream<String?> get error => _errorSubject.stream;

  StoreService({required this.authService}) {
    _loadingSubject.add(false);
    _errorSubject.add(null);
  }

  Future<void> loadStores() async {
    _loadingSubject.add(true);
    _errorSubject.add(null);
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/stores'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final stores = data.map((json) => Store.fromMap(json)).toList();
        _storesSubject.add(stores);
      } else {
        throw Exception('Failed to load stores');
      }
    } catch (e) {
      _logger.e('Error loading stores', error: e);
      _errorSubject.add(e.toString());
    } finally {
      _loadingSubject.add(false);
    }
  }

  Future<void> toggleFavorite(int storeId) async {
    try {
      _logger.i('Attempting to toggle favorite for store ID: $storeId');

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        _logger.e('No user email found in SharedPreferences');
        throw Exception('No user email found');
      }
      _logger.d('User email found: $email');

      // Check if the store is already in favorites
      final favoriteStores = await getFavoriteStores();
      final isAlreadyFavorite = favoriteStores.any(
        (store) => store.id == storeId,
      );
      _logger.d('Store is${isAlreadyFavorite ? '' : ' not'} in favorites');

      final endpoint = isAlreadyFavorite ? 'remove' : 'add';
      final url = Uri.parse('$_baseUrl/api/stores/favorite/$endpoint');
      _logger.d('Making request to: ${url.toString()}');

      final requestBody = {
        'email': email,
        'storeId': storeId,
      };
      _logger.d('Request body: ${json.encode(requestBody)}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response headers: ${response.headers}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _logger.i('Successfully toggled favorite status');
        // Refresh the favorite stores list
        await loadFavoriteStores();
      } else {
        String errorMessage;
        try {
          final contentType = response.headers['content-type'];
          if (contentType?.contains('application/json') == true) {
            final errorData = json.decode(response.body);
            errorMessage = errorData['error'] ?? 'Unknown error occurred';
          } else {
            errorMessage =
                'Server error: ${response.statusCode} - ${response.body}';
          }
        } catch (e) {
          errorMessage = 'Failed to parse error response: ${response.body}';
        }
        _logger.e('Server returned error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      _logger.e('Error toggling favorite', error: e, stackTrace: stackTrace);
      _errorSubject.add(e.toString());
      rethrow;
    }
  }

  Future<void> loadFavoriteStores() async {
    try {
      final favoriteStores = await getFavoriteStores();
      _storesSubject.add(favoriteStores);
    } catch (e) {
      _logger.e('Error loading favorite stores', error: e);
      _errorSubject.add(e.toString());
      rethrow;
    }
  }

  Future<List<Store>> getFavoriteStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception('No user email found');
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl/api/users/$email/favorites'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Store.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load favorite stores');
      }
    } catch (e) {
      _logger.e('Error getting favorite stores', error: e);
      _errorSubject.add(e.toString());
      rethrow;
    }
  }

  Future<List<Store>> getAllStores() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/stores'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _logger.d('Raw store data from server: $data');

        // Log the first store's data if available
        if (data.isNotEmpty) {
          _logger.d('First store data: ${data[0]}');
          _logger.d(
              'First store latitude type: ${data[0]['latitude'].runtimeType}');
          _logger.d(
              'First store longitude type: ${data[0]['longitude'].runtimeType}');
        }

        return data.map((json) {
          try {
            return Store.fromMap(json);
          } catch (e) {
            _logger.e('Error parsing store data: $json', error: e);
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load stores');
      }
    } catch (e) {
      _logger.e('Error getting all stores', error: e);
      rethrow;
    }
  }

  Future<List<Store>> searchStoresByProduct(String productName) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$_baseUrl/stores/search',
        ).replace(queryParameters: {'product': productName}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Store.fromMap(json)).toList();
      } else {
        throw Exception('Failed to search stores');
      }
    } catch (e) {
      throw Exception('Failed to search stores: $e');
    }
  }

  void dispose() {
    _storesSubject.close();
    _loadingSubject.close();
    _errorSubject.close();
    _client.close();
  }
}
