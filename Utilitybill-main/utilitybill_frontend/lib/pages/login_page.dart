import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Derive username from email local-part (must match registration logic)
    String username;
    final atIndex = email.indexOf('@');
    if (atIndex > 0) {
      username = email.substring(0, atIndex);
    } else {
      // Fallback: use full email if malformed
      username = email;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login/');
    final body = jsonEncode({'username': username, 'password': password});

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>?;
        final profile = data['profile'] as Map<String, dynamic>?;
        final role = profile?['role']?.toString() ?? 'user';
        final firstName = (user?['first_name'] ?? '').toString();
        final lastName = (user?['last_name'] ?? '').toString();
        final computedFullName = ("$firstName $lastName").trim();
        final profileFullName = (profile?['full_name'] ?? '').toString();
        final fullName =
            (computedFullName.isNotEmpty ? computedFullName : profileFullName)
                .trim();

        // Extract and save session cookie
        final cookies = resp.headers['set-cookie'];
        if (cookies != null) {
          final sessionMatch = RegExp(r'sessionid=([^;]+)').firstMatch(cookies);
          if (sessionMatch != null) {
            final sessionId = sessionMatch.group(1);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('sessionid', sessionId!);
            print('Session saved: $sessionId');
          }
        }

        // Persist minimal session info + token (if provided)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_email',
          user?['email']?.toString() ?? email,
        );
        await prefs.setString(
          'user_username',
          user?['username']?.toString() ?? username,
        );
        await prefs.setString('user_role', role);
        final token = (data['token'] ?? '').toString();
        if (token.isNotEmpty) {
          await prefs.setString('auth_token', token);
        }
        if (fullName.isNotEmpty) {
          await prefs.setString('full_name', fullName);
        }

        setState(() {
          _isLoading = false;
        });

        // Role-based routing
        final isExplicitAdminCreds =
            email == 'admin@gmail.com' && password == 'Admin@123';
        if (role == 'admin' || isExplicitAdminCreds) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'utility') {
          Navigator.pushReplacementNamed(context, '/utility');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful'),
            backgroundColor: Color(0xFF4B9A8F),
          ),
        );
      } else {
        String message = 'Incorrect email or password';
        try {
          final err = jsonDecode(resp.body);
          if (err is Map && err['error'] != null) {
            final serverMsg = err['error'].toString();
            if (serverMsg.toLowerCase().contains('invalid credentials')) {
              message = 'Incorrect email or password';
            } else {
              message = serverMsg;
            }
          }
        } catch (_) {}
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var heightOfScreen = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Curved Top Section
            ClipPath(
              clipper: CurvedBottomClipper(),
              child: Container(
                height: heightOfScreen * 0.45,
                decoration: const BoxDecoration(color: Color(0xFF7FD9CE)),
              ),
            ),
            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Log in Title
                    const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Email Field
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B9A8F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        hintStyle: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 16,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF4B9A8F),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B9A8F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      decoration: InputDecoration(
                        hintText: '********',
                        hintStyle: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 16,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF4B9A8F),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Log in Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B9A8F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Log in',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Sign up Link
                    // No sign-up link needed in no-auth flow
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Clipper for the curved top section
class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 100);

    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 30);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, size.height - 60);
    final secondEndPoint = Offset(size.width, size.height - 40);

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
