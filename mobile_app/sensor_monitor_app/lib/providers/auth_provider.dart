import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoggedInInitialized = false;
  String _baseUrl = 'https://humancc.site/shahidatulhidayah/iottraining/backend'; // Your backend URL
  String? _username;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoggedInInitialized => _isLoggedInInitialized;
  String? get username => _username;

  // Check login status on app start
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _username = prefs.getString('username'); // Load username
    _isLoggedInInitialized = true;
    notifyListeners();
  }

  // Login method
  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        body: {'username': username, 'password': password},
      );

      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username); // Save username
        _isLoggedIn = true;
        _username = username; // Set current username
        notifyListeners();
        return null; // Indicate success
      } else {
        return responseData['message']; // Return error message
      }
    } catch (e) {
      print('Login error: $e');
      return 'Login failed. Please try again.'; // Generic error message
    }
  }

  // Register method
  Future<String?> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register.php'),
        body: {'username': username, 'password': password},
      );

      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        return null; // Indicate success
      } else {
        return responseData['message']; // Return error message
      }
    } catch (e) {
      print('Registration error: $e');
      return 'Registration failed. Please try again.'; // Generic error message
    }
  }

  // Logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _isLoggedIn = false;
    notifyListeners();
  }
} 