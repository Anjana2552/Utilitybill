import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLaptopScreen = constraints.maxWidth >= 600;
          final backgroundImage = isLaptopScreen
              ? 'assets/images/landing_bg.png'
              : 'assets/images/landing_bg_mobile.png';
          
          // Center alignment for better text positioning on large screens
          final alignment = isLaptopScreen 
              ? Alignment.centerLeft  // Align to center-left for large screens
              : Alignment.topCenter;

          return Stack(
            children: [
              // Background Image
              SizedBox.expand(
                child: Image.asset(
                  backgroundImage,
                  fit: BoxFit.cover,  // Fill the entire screen
                  alignment: alignment,
                  filterQuality: FilterQuality.high,
                ),
              ),
              
              // Buttons at the bottom
              Positioned(
                bottom: isLaptopScreen ? 60 : 40,
                left: isLaptopScreen ? constraints.maxWidth * 0.3 : 24,
                right: isLaptopScreen ? constraints.maxWidth * 0.3 : 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Register Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1a237e),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isLaptopScreen ? 18 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(
                            fontSize: isLaptopScreen ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Login Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1a237e),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isLaptopScreen ? 18 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: isLaptopScreen ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
