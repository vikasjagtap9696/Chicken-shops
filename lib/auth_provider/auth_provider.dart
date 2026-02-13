import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  String? _userRole;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;

  AuthProvider() {
    _checkLoginStatus();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userName = prefs.getString('userName');
    _userEmail = prefs.getString('userEmail');
    _userRole = prefs.getString('userRole');
    notifyListeners();
  }

  // Login function
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    // TODO: Call your Express.js backend API
    // Example API call:
    /*
    try {
      final response = await http.post(
        Uri.parse('http://your-server:5000/api/auth/login'),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _saveUserData(data, rememberMe);
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
    */

    // Demo login for testing
    if (email == 'admin@123.com' && password == '123456') {
      await _saveUserData({
        'name': 'Admin User',
        'email': email,
        'role': 'owner',
        'token': 'demo_token_123',
      }, rememberMe);
      return true;
    }

    return false;
  }

  // Save user data
  Future<void> _saveUserData(Map<String, dynamic> userData, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', userData['name']);
      await prefs.setString('userEmail', userData['email']);
      await prefs.setString('userRole', userData['role']);
      await prefs.setString('authToken', userData['token']);
    }

    _isLoggedIn = true;
    _userName = userData['name'];
    _userEmail = userData['email'];
    _userRole = userData['role'];
    notifyListeners();
  }

  // Logout function
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _userRole = null;
    notifyListeners();
  }

  // Register function
  Future<bool> register(String name, String email, String password) async {
    // TODO: Call your Express.js backend API
    // Demo registration
    return true;
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    // TODO: Call your Express.js backend API
    return true;
  }
}