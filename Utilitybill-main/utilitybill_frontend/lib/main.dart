import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'config/app_theme.dart';
import 'package:utilitybill_frontend/pages/users/bill_payment.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/users/home_page.dart';
import 'pages/users/chat_page.dart';
import 'pages/users/payment_history_page.dart';
import 'pages/users/rewards_page.dart';
import 'pages/users/wallet_page.dart';
import 'pages/users/payment_success_page.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/utility/utility_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: AppTheme.lightTheme(),
      // Single-theme app: dark mode removed
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminDashboard(),
        '/utility': (context) => const UtilityDashboard(),
        '/user/bill_payment': (context) => const BillPaymentPage(),
        '/user/payment_history': (context) => const PaymentHistoryPage(),
        '/user/rewards': (context) => const RewardsPage(),
        '/user/wallet': (context) => const WalletPage(),
        '/user/payment_success': (context) => const PaymentSuccessPage(),
        '/user/chat': (context) => const ChatPage(),
      },
    );
  }
}
