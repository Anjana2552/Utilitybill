import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'forgot_password_page.dart';

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
            debugPrint('Session saved: $sessionId');
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

        if (!mounted) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login successful'),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
        if (!mounted) return;
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

  void _goBackToLanding() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    var heightOfScreen = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Curved Top Section
            ClipPath(
              clipper: CurvedBottomClipper(),
              child: Container(
                height: heightOfScreen * 0.45,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: Stack(
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _goBackToLanding,
                            tooltip: 'Back',
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Sign in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    const SizedBox(height: 24),
                    // Email Field
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Password Field
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '********',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Log in Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
