// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  User? _firebaseUser;
  UserModel? _user;
  String? _error;
  bool _loading = false;

  // Getters
  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Constructor - initialize auth state listener
  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // Handle auth state changes
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _firebaseUser = null;
      _user = null;
    } else {
      _firebaseUser = firebaseUser;

      try {
        final userData = await _authService.getUserData(firebaseUser.uid);
        _user = userData;
        _status = AuthStatus.authenticated;
      } catch (e) {
        _error = e.toString();
        _status = AuthStatus.unauthenticated;
      }
    }

    notifyListeners();
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);
      // The auth state listener will handle the rest
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Sign up
  Future<void> signUp(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _authService.createUserWithEmailAndPassword(
        email,
        password,
        name,
        role,
      );
      // The auth state listener will handle the rest
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _loading = true;
      notifyListeners();

      await _authService.signOut();
      // The auth state listener will handle the rest
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? role,
    String? photoUrl,
  }) async {
    try {
      if (_user == null) return;

      _loading = true;
      _error = null;
      notifyListeners();

      final updatedUser = _user!.copyWith(
        name: name ?? _user!.name,
        role: role ?? _user!.role,
        photoUrl: photoUrl ?? _user!.photoUrl,
      );

      await _authService.updateUserData(updatedUser);
      _user = updatedUser;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
