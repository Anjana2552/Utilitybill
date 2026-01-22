import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:utilitybill_frontend/pages/users/bill_payment.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/users/home_page.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/utility/utility_dashboard.dart';

void main() {
  // Ensure debug baseline/size paints are disabled (removes yellow lines)
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Utility Bill',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B9A8F),
          primary: const Color(0xFF4B9A8F),
        ),
        useMaterial3: true,
      ),
      // Define initial route
      initialRoute: '/',
      // Define named routes
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminDashboard(),
        '/utility': (context) => const UtilityDashboard(),
        '/user/bill_payment': (context) => const BillPaymentPage(),
      },
    );
  }
}
