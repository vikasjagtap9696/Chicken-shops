import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:5000/api'; 
  
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _loadSavedSession();
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final trimmedEmail = email.trim();

    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': trimmedEmail,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5)); // Set a timeout

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _token = responseData['token'];
        _currentUser = UserModel.fromJson(responseData['data']);
        
        await _saveUserSession(_token!, responseData['data']);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = responseData['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Server connection failed, checking for offline admin login: $e');
      
      // जर सर्व्हर बंद असेल, तर डिफॉल्ट ॲडमिन क्रेडेंशियल्स तपासा
      if (trimmedEmail == 'admin@chickenshop.com' && password == '123456') {
        _token = 'offline_admin_token';
        _currentUser = UserModel(
          id: '0',
          name: 'Admin (Offline)',
          email: trimmedEmail,
          phone: '0000000000',
          shopName: 'Chicken Mart',
          role: 'admin',
          createdAt: DateTime.now(),
        );

        await _saveUserSession(_token!, _currentUser!.toJson());
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = "Server connection failed. Default login not matched.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email.trim()}),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['message'] ?? 'Failed to send reset email';
        return false;
      }
    } catch (e) {
      _error = "Server connection failed.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
    _token = null;
    notifyListeners();
  }

  Future<void> _saveUserSession(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userData', json.encode(userData));
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      _token = prefs.getString('token');
      final userDataStr = prefs.getString('userData');
      if (userDataStr != null) {
        try {
          _currentUser = UserModel.fromJson(json.decode(userDataStr));
        } catch (e) {
          debugPrint('Error decoding user data: $e');
        }
      }
    }
    _isInitialized = true;
    notifyListeners();
  }
}
