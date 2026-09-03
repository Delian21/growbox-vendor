import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String? _vendorName;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String? get vendorName => _vendorName;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock validation
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Invalid email or password';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Mock success
    _isAuthenticated = true;
    _vendorName = 'Farm Fresh Enterprises';
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock success
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _isAuthenticated = false;
    _vendorName = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
