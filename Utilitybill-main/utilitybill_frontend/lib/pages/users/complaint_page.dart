import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Billing Issue';
  final List<String> _categories = [
    'Billing Issue',
    'Payment Issue',
    'Technical Problem',
    'Service Quality',
    'Account Issue',
    'Other',
  ];
  
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _myComplaints = [];
  bool _loadingComplaints = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      
      if (username.isEmpty) {
        setState(() => _loadingComplaints = false);
        return;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/complaints/list/?username=$username');
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final complaints = (data['complaints'] as List<dynamic>?) ?? [];
        
        if (mounted) {
          setState(() {
            _myComplaints = complaints.map((c) => c as Map<String, dynamic>).toList();
            _loadingComplaints = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingComplaints = false);
      }
    } catch (e) {
      print('Error loading complaints: $e');
      if (mounted) setState(() => _loadingComplaints = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      
      if (username.isEmpty) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/complaints/add/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'category': _selectedCategory,
          'subject': _subjectController.text.trim(),
          'description': _descriptionController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _subjectController.clear();
        _descriptionController.clear();
        setState(() => _selectedCategory = 'Billing Issue');
        
        // Reload complaints
        _loadComplaints();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Failed to submit complaint'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA726';
      case 'in progress':
      case 'in_progress':
        return '#42A5F5';
      case 'resolved':
        return '#66BB6A';
      case 'closed':
        return '#9E9E9E';
      default:
        return '#FFA726';
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
                  height: 140,
                  overlay: null,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: scheme.onPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Text(
                    'Complaints',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Submit Complaint Form
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submit a Complaint',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Category Dropdown
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.category_outlined),
                                ),
                                items: _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedCategory = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Subject
                              TextFormField(
                                controller: _subjectController,
                                decoration: InputDecoration(
                                  labelText: 'Subject',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.subject),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a subject';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Description
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  hintText: 'Describe your complaint in detail...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignLabelWithHint: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  if (value.trim().length < 20) {
                                    return 'Description should be at least 20 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitComplaint,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Submit Complaint'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // My Complaints Section
                    Text(
                      'My Complaints',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_loadingComplaints)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_myComplaints.isEmpty)
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No complaints submitted yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _myComplaints[index];
                          final status = complaint['status']?.toString() ?? 'pending';
                          final statusColor = _getStatusColor(status);
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.report_problem_outlined,
                                  color: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))),
                                ),
                              ),
                              title: Text(
                                complaint['subject']?.toString() ?? 'No subject',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                complaint['category']?.toString() ?? 'General',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Chip(
                                label: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Description:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        complaint['description']?.toString() ?? 'No description',
                                        style: TextStyle(color: Colors.grey.shade800),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Submitted: ${complaint['created_at']?.toString() ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (complaint['response'] != null && complaint['response'].toString().isNotEmpty) ...[
                                        const Divider(height: 24),
                                        Text(
                                          'Response:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          complaint['response'].toString(),
                                          style: TextStyle(color: Colors.grey.shade800),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
