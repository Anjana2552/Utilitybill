import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  int? _profileId;
  String _errorMessage = '';
  List<String> _utilities = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _houseNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _showError('No authentication token found');
        return;
      }

      // Fetch user profile from backend
      final uri = Uri.parse('${ApiConfig.baseUrl}/profiles/');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle both list and single object responses
        Map<String, dynamic>? profile;
        
        if (data is List && data.isNotEmpty) {
          profile = data[0] as Map<String, dynamic>;
        } else if (data is Map) {
          profile = data as Map<String, dynamic>;
        }

        if (profile != null) {
          final profileData = profile;
          setState(() {
            _profileId = profileData['id'] as int?;
            _fullNameController.text = profileData['full_name'] ?? '';
            _emailController.text = profileData['email'] ?? '';
            _phoneController.text = profileData['phone'] ?? '';
            _houseNumberController.text = profileData['house_number'] ?? '';
            _addressController.text = profileData['address'] ?? '';
          });
        }
      } else {
        _showError('Failed to load profile data');
      }

      // Fetch user utilities
      await _loadUserUtilities();
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserUtilities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        return;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/user-utility/list/');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<String> utilityTypes = [];
        String? houseNumberFromUtility;

        if (data is List) {
          for (var item in data) {
            if (item is Map && item.containsKey('utility_type')) {
              final utilityType = item['utility_type'] as String?;
              if (utilityType != null && !utilityTypes.contains(utilityType)) {
                utilityTypes.add(utilityType);
              }
              
              // Get house_number from the first utility that has it
              if (houseNumberFromUtility == null && item.containsKey('house_number')) {
                final houseNum = item['house_number'] as String?;
                if (houseNum != null && houseNum.isNotEmpty) {
                  houseNumberFromUtility = houseNum;
                }
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _utilities = utilityTypes;
            // Auto-fill house number from utility if not already set
            if (houseNumberFromUtility != null && 
                _houseNumberController.text.isEmpty) {
              _houseNumberController.text = houseNumberFromUtility;
            }
          });
        }
      }
    } catch (e) {
      // Silently fail utilities loading
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profileId == null) {
      _showError('Profile ID not found');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _showError('Authentication token not found. Please login again.');
        return;
      }

      final uri =
          Uri.parse('${ApiConfig.baseUrl}/profiles/$_profileId/');
      final body = jsonEncode({
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'house_number': _houseNumberController.text.trim(),
        'address': _addressController.text.trim(),
      });

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Update SharedPreferences with new data
        await prefs.setString('full_name', _fullNameController.text.trim());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate back to profile page
          Navigator.of(context).pop(true);
        }
      } else {
        String message = 'Failed to update profile';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.isNotEmpty) {
            message = errorData.values.first.toString();
          }
        } catch (_) {}
        _showError(message);
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Stack(
              children: [
                BlueGreenHeader(
                  height: 150,
                  overlay: null,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: scheme.onPrimary),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: SafeArea(
                    child: Text(
                      'Edit Profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: scheme.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full Name
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: scheme.outline,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                if (value.trim().length < 2) {
                                  return 'Full name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: scheme.outline,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(
                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: scheme.outline,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 10) {
                                  return 'Phone number must be at least 10 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // House Number
                            TextFormField(
                              controller: _houseNumberController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'House Number',
                                hintText: 'Enter your house number',
                                prefixIcon: const Icon(Icons.home),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: scheme.outline,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 1) {
                                  return 'House number must be at least 1 character';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Address
                            TextFormField(
                              controller: _addressController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                hintText: 'Enter your address',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: scheme.outline,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 5) {
                                  return 'Address must be at least 5 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            // Utility Types Section
                            if (_utilities.isNotEmpty) ...[
                              Text(
                                'Added Utilities',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _utilities
                                    .map(
                                      (utility) => Chip(
                                        label: Text(utility),
                                        backgroundColor:
                                            scheme.primaryContainer,
                                        labelStyle: TextStyle(
                                          color: scheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        avatar: Icon(
                                          Icons.check_circle,
                                          color: scheme.onPrimaryContainer,
                                          size: 18,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 32),
                            ],
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isSaving ? null : _handleSaveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  disabledBackgroundColor:
                                      scheme.primary.withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isSaving
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: scheme.onPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          color: scheme.onPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Cancel Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () =>
                                        Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
