import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // Change this to your computer's IP address if testing on a physical device
  // For Android Emulator: use 10.0.2.2
  // For iOS Simulator: use localhost
  // For Physical Device: use your computer's IP (e.g., 192.168.1.100)
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // For web or desktop testing, use this instead:
  // static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Register a new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password2': password2,
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': _parseErrorMessage(errorData),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'profile': UserProfile.fromJson(data['profile']),
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Logged out successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Logout failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/current-user/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get user data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Helper method to parse error messages
  static String _parseErrorMessage(Map<String, dynamic> errorData) {
    if (errorData.containsKey('username')) {
      return 'Username: ${errorData['username'][0]}';
    } else if (errorData.containsKey('email')) {
      return 'Email: ${errorData['email'][0]}';
    } else if (errorData.containsKey('password')) {
      return 'Password: ${errorData['password'][0]}';
    } else if (errorData.containsKey('password2')) {
      return errorData['password2'][0];
    } else {
      return errorData.toString();
    }
  }
}
