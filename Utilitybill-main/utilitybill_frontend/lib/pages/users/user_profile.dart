import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../widgets/theme_header.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  ImageProvider? _profileImage;

  void _showChangePhotoSheet() {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image picker not set up yet')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera not set up yet')),
                );
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
                  setState(() => _profileImage = null);
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
    const accent = Color(0xFF4B9A8F);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                BlueGreenHeader(
                  height: 220,
                  overlay: _AvatarEdit(
                    image: _profileImage,
                    onTap: _showChangePhotoSheet,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      leading: const Icon(Icons.person_outline, color: accent),
                      title: const Text('Edit profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(
                        Icons.credit_card_outlined,
                        color: accent,
                      ),
                      title: const Text('Payment Details'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Payment Details'),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: accent,
                      ),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Settings'),
                    ),
                  ),
                  // Added sections
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: accent,
                      ),
                      title: const Text('Saved Address'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Saved Address'),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(Icons.credit_card, color: accent),
                      title: const Text('Saved Credit/Debit Cards'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Saved Credit/Debit Cards'),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(
                        Icons.notifications_outlined,
                        color: accent,
                      ),
                      title: const Text('Notification Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Notification Settings'),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline, color: accent),
                      title: const Text('Privacy Center'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Privacy Center'),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(
                        Icons.rate_review_outlined,
                        color: accent,
                      ),
                      title: const Text('Reviews'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Reviews'),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(
                        Icons.article_outlined,
                        color: accent,
                      ),
                      title: const Text('Terms, Policies & Licenses'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _soon(context, 'Terms, Policies & Licenses'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: const Color(0xFFFFF1F1),
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
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
        items: const [
          Icon(Icons.home, size: 26, color: Colors.white),
          Icon(Icons.payment, size: 26, color: Colors.white),
          Icon(Icons.person, size: 26, color: Colors.white),
        ],
        index: 2,
        color: const Color(0xFF7FD9CE),
        buttonBackgroundColor: const Color(0xFF4B9A8F),
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
          // index==2 stays on profile
        },
      ),
    );
  }
}

class _AvatarEdit extends StatelessWidget {
  final ImageProvider? image;
  final VoidCallback onTap;
  const _AvatarEdit({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFB2E8E1),
              backgroundImage: image,
              child: image == null
                  ? const Icon(Icons.person, size: 36, color: Colors.white)
                  : null,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4B9A8F),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
