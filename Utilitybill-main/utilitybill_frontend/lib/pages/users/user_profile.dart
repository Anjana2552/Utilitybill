import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../widgets/theme_header.dart';
import 'edit_profile_page.dart';
import 'payment_details_page.dart';
import 'review_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                BlueGreenHeader(
                  height: 250,
                  overlay: _AvatarWithName(
                    image: _profileImage,
                    username: _fullName.isNotEmpty ? _fullName : _username,
                    onTap: _showChangePhotoSheet,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: scheme.onPrimary),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(Icons.person_outline, color: scheme.secondary),
                      title: const Text('Edit profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                        
                        // Reload user data if profile was updated
                        if (result == true && mounted) {
                          _loadUserData();
                        }
                      },
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(
                        Icons.credit_card_outlined,
                        color: scheme.secondary,
                      ),
                      title: const Text('Payment Details'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentDetailsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications_outlined,
                        color: scheme.secondary,
                      ),
                      title: const Text('Notification Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Notification Settings'),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(Icons.lock_outline, color: scheme.secondary),
                      title: const Text('Privacy Center'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Privacy Center'),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(
                        Icons.rate_review_outlined,
                        color: scheme.secondary,
                      ),
                      title: const Text('Reviews'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReviewPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(
                        Icons.article_outlined,
                        color: scheme.secondary,
                      ),
                      title: const Text('Terms, Policies & Licenses'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Terms, Policies & Licenses'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: scheme.errorContainer,
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _soon(context, 'Logout'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        items: [
          Icon(Icons.home, size: 26, color: scheme.onPrimary),
          Icon(Icons.payment, size: 26, color: scheme.onPrimary),
          Icon(Icons.chat_bubble_outline, size: 26, color: scheme.onPrimary),
          Icon(Icons.person, size: 26, color: scheme.onPrimary),
        ],
        index: 3,
        color: scheme.primary,
        buttonBackgroundColor: scheme.primaryContainer,
        backgroundColor: scheme.background,
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
          // index==3 stays on profile
        },
      ),
    );
  }
}

class _AvatarWithName extends StatelessWidget {
  final ImageProvider? image;
  final String username;
  final VoidCallback onTap;
  const _AvatarWithName({
    required this.image,
    required this.username,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: image,
                  child: image == null
                      ? Icon(
                          Icons.account_circle,
                          size: 64,
                          color: Colors.white.withOpacity(0.9),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surface,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              username.isNotEmpty ? username : 'User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
