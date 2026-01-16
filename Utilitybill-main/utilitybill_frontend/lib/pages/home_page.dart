import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../widgets/theme_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('full_name') ?? prefs.getString('user_username') ?? 'User';
    if (!mounted) return;
    setState(() {
      _fullName = name;
    });
  }

  final List<Widget> _tabs = const [
    _TabPlaceholder(title: 'Home'),
    _TabPlaceholder(title: 'Bills'),
    _TabPlaceholder(title: 'Profile'),
    _TabPlaceholder(title: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Welcome back, $_fullName'),
        backgroundColor: const Color(0xFF7FD9CE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BlueGreenHeader(height: 220),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0.05, 0.02),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offsetAnimation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey<int>(_currentIndex),
                  color: Colors.white,
                  child: _tabs[_currentIndex],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        items: const [
          Icon(Icons.home, size: 26, color: Colors.white),
          Icon(Icons.receipt_long, size: 26, color: Colors.white),
          Icon(Icons.person, size: 26, color: Colors.white),
          Icon(Icons.settings, size: 26, color: Colors.white),
        ],
        color: const Color(0xFF7FD9CE),
        buttonBackgroundColor: const Color(0xFF4B9A8F),
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  final String title;
  const _TabPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3142),
        ),
      ),
    );
  }
}
