import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'edit_profile_page.dart';
import 'payment_details_page.dart';
import 'review_page.dart';
import 'privacy_center_page.dart';
import 'terms_disclaimer_page.dart';
import 'about_us_page.dart';
import '../notifications.dart';
import '../../services/notifications_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  ImageProvider? _profileImage;
  String _username = '';
  String _fullName = '';
  final ImagePicker _picker = ImagePicker();
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) return;
      
      final svc = NotificationsService();
      final notifications = await svc.loadFromBackend(username);
      final unreadCount = notifications.where((n) => !n.read).length;
      if (mounted) setState(() => _unreadNotifCount = unreadCount);
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('user_username') ?? '';
      _fullName = prefs.getString('full_name') ?? _username;
      // Load saved profile image path if exists
      if (!kIsWeb) {
        final imagePath = prefs.getString('profile_image_path');
        if (imagePath != null && imagePath.isNotEmpty) {
          try {
            _profileImage = FileImage(File(imagePath));
          } catch (e) {
            // Image file might not exist anymore
            prefs.remove('profile_image_path');
          }
        }
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read as bytes and use MemoryImage
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _profileImage = MemoryImage(bytes);
          });
          
          // Save as base64 for web
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_web', pickedFile.path);
        } else {
          setState(() {
            _profileImage = FileImage(File(pickedFile.path));
          });
          
          // Save image path to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_path', pickedFile.path);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Image picker not available on web browser. Please use mobile app.')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (kIsWeb) {
            _profileImage = NetworkImage(pickedFile.path);
          } else {
            _profileImage = FileImage(File(pickedFile.path));
          }
        });
        
        // Save image path to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', pickedFile.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _profileImage = null;
    });
    
    // Remove from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed')),
      );
    }
  }

  void _showChangePhotoSheet() {
    if (kIsWeb) {
      // Show simplified dialog for web
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Profile Photo'),
          content: const Text(
            'Image upload is currently not fully supported on web browsers. '
            'Please use the mobile app for full profile photo functionality.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageFromCamera();
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Clear user session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Navigate to login page and remove all previous routes
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Curved Header
          ClipPath(
            clipper: ProfileWaveClipper(),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color.fromARGB(255, 1, 36, 64), const Color.fromARGB(255, 0, 58, 116)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Row(
                    children: [
                      // Profile Avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: _profileImage,
                          child: _profileImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.blue.shade700,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Username
                      Expanded(
                        child: Text(
                          _fullName.isNotEmpty ? _fullName : _username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit profile',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                    if (result == true && mounted) {
                      _loadUserData();
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.payment_outlined,
                  title: 'Payment Details',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentDetailsPage(),
                      ),
                    );
                  },
                ),
                // Special notification menu with badge
                Container(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        if (_unreadNotifCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadNotifCount > 99 ? '99+' : _unreadNotifCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                      // Reload unread count when coming back
                      _loadUnreadCount();
                    },
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Center',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyCenterPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.star_outline,
                  title: 'Reviews',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Terms & Disclaimers',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsDisclaimerPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutUsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 24, thickness: 1),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: _logout,
                  iconColor: Colors.pink.shade400,
                  textColor: Colors.pink.shade400,
                  backgroundColor: Colors.pink.shade50,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        items: [
          Icon(
            Icons.home,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.payment,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.chat_bubble_outline,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.person,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
        index: 3,
        color: Theme.of(context).colorScheme.primary,
        buttonBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
            return;
          }
          if (index == 1) {
            Navigator.pushNamed(context, '/user/bill_payment');
            return;
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/user/chat');
            return;
          }
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    Color? backgroundColor,
  }) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.blue.shade700,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Custom clipper for curved header
class ProfileWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
