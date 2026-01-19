import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../widgets/theme_header.dart';
import 'user_profile.dart';
import 'view_bills_page.dart';
import 'add_bill_page.dart';
import '../utility/utility_payment.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _fullName = '';
  ImageProvider? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  void _showChangePhotoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _profileImage = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
    UtilityPaymentPage(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Text('Welcome back, $_fullName'),
        backgroundColor: const Color(0xFF7FD9CE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF7FD9CE)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: _currentIndex == 0,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _currentIndex = 0);
                },
              ),
              ExpansionTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('My Bills'),
                childrenPadding: const EdgeInsets.only(left: 24),
                children: [
                  ListTile(
                    leading: const Icon(Icons.visibility_outlined),
                    title: const Text('View Bills'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ViewBillsPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add_outlined),
                    title: const Text('Add Bill'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddBillPage()),
                      );
                    },
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Payment'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/utility');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Payment History'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment History coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserProfilePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlueGreenHeader(
              height: 220,
              overlay: _currentIndex == 2
                  ? _AvatarEdit(
                      image: _profileImage,
                      onTap: _showChangePhotoSheet,
                    )
                  : null,
            ),
            // No spacer needed when avatar is centered in the header
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
          Icon(Icons.payment, size: 26, color: Colors.white),
          Icon(Icons.person, size: 26, color: Colors.white),
        ],
        color: const Color(0xFF7FD9CE),
        buttonBackgroundColor: const Color(0xFF4B9A8F),
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserProfilePage()),
            );
            return;
          }
          setState(() => _currentIndex = index);
        },
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4B9A8F);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: accent),
            title: const Text('Personal Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Personal Details'),
          ),
        ),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.credit_card_outlined, color: accent),
            title: const Text('Payment Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Payment Details'),
          ),
        ),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.settings_outlined, color: accent),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Settings'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Color(0xFFFFF1F1),
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            onTap: () => _soon(context, 'Logout'),
          ),
        ),
      ],
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

