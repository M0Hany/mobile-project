import 'package:rxdart/rxdart.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'base_state.dart';

class AuthState extends BaseState<AuthStateData> {
  final AuthService _authService;
  final BehaviorSubject<User?> _userSubject = BehaviorSubject<User?>();
  final BehaviorSubject<bool> _isAuthenticatedSubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _isLoadingSubject = BehaviorSubject<bool>.seeded(
    false,
  );

  AuthState(this._authService) {
    _initializeState();
  }

  void _initializeState() {
    updateState(
      AuthStateData(user: null, isAuthenticated: false, isLoading: false),
    );
  }

  Stream<User?> get user => _userSubject.stream;
  Stream<bool> get isAuthenticated => _isAuthenticatedSubject.stream;
  Stream<bool> get isLoading => _isLoadingSubject.stream;

  Future<void> login(String email, String password) async {
    _isLoadingSubject.add(true);
    try {
      final user = await _authService.login(email, password);
      _userSubject.add(user);
      _isAuthenticatedSubject.add(true);
      updateState(
        AuthStateData(user: user, isAuthenticated: true, isLoading: false),
      );
    } catch (e) {
      // Handle error
      rethrow;
    } finally {
      _isLoadingSubject.add(false);
    }
  }

  Future<void> register(User user, String password) async {
    _isLoadingSubject.add(true);
    try {
      final registeredUser = await _authService.register(user, password);
      _userSubject.add(registeredUser);
      _isAuthenticatedSubject.add(true);
      updateState(
        AuthStateData(
          user: registeredUser,
          isAuthenticated: true,
          isLoading: false,
        ),
      );
    } catch (e) {
      // Handle error
      rethrow;
    } finally {
      _isLoadingSubject.add(false);
    }
  }

  Future<void> logout() async {
    _isLoadingSubject.add(true);
    try {
      await _authService.logout();
      _userSubject.add(null);
      _isAuthenticatedSubject.add(false);
      updateState(
        AuthStateData(user: null, isAuthenticated: false, isLoading: false),
      );
    } catch (e) {
      // Handle error
      rethrow;
    } finally {
      _isLoadingSubject.add(false);
    }
  }

  @override
  void dispose() {
    _userSubject.close();
    _isAuthenticatedSubject.close();
    _isLoadingSubject.close();
    super.dispose();
  }
}

class AuthStateData {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;

  AuthStateData({
    required this.user,
    required this.isAuthenticated,
    required this.isLoading,
  });
}
