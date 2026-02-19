import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      debugPrint("Login Provider Error: $e");
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, String phone) async {
    _setLoading(true);
    try {
      final user = await _authService.register(email, password, name, phone);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      debugPrint("Register Provider Error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> checkCurrentUser() async {
    _isLoading = true;
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserLastSeen() async {
    await _authService.updateUserLastSeen();
    // No need to notifyListeners() usually, as this is a background firestore update
  }
}