import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthService {
  static const String _userKey = 'user';
  static const String _profileKey = 'profile';
  static const String _isLoggedInKey = 'isLoggedIn';

  // Save user data after login
  static Future<void> saveUserData(User user, UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get saved user
  static Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Get saved profile
  static Future<UserProfile?> getSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    if (profileJson != null) {
      return UserProfile.fromJson(jsonDecode(profileJson));
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear user data on logout
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_profileKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}
