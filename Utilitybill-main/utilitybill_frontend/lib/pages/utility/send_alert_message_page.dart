import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../config/api_config.dart';

class SendAlertMessagePage extends StatefulWidget {
  final String utilityType;
  
  const SendAlertMessagePage({
    super.key,
    required this.utilityType,
  });

  @override
  State<SendAlertMessagePage> createState() => _SendAlertMessagePageState();
}

class _SendAlertMessagePageState extends State<SendAlertMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  String _selectedPriority = 'medium';
  
  final List<Map<String, dynamic>> _priorityOptions = [
    {
      'value': 'low',
      'label': 'Low Priority',
      'icon': Icons.info_outline,
      'color': Colors.blue,
    },
    {
      'value': 'medium',
      'label': 'Medium Priority',
      'icon': Icons.warning_amber_outlined,
      'color': Colors.orange,
    },
    {
      'value': 'high',
      'label': 'High Priority',
      'icon': Icons.priority_high,
      'color': Colors.red,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAlert() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _sending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';

      final uri = Uri.parse('${ApiConfig.baseUrl}/alerts/send-broadcast/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'utility_type': widget.utilityType,
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'priority': _selectedPriority,
          'sender_username': username,
        }),
      );

      if (mounted) {
        setState(() => _sending = false);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final count = data['users_notified'] ?? 0;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Alert sent to $count ${widget.utilityType} users!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Clear form
          _titleController.clear();
          _messageController.clear();
          setState(() => _selectedPriority = 'medium');
        } else {
          final error = jsonDecode(response.body)['error'] ?? 'Failed to send alert';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Alert Message'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        color: Colors.blue.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broadcast Alert',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Send notification to all ${widget.utilityType} users',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Priority selection
              Text(
                'Priority Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              
              ...List.generate(_priorityOptions.length, (index) {
                final option = _priorityOptions[index];
                return RadioListTile<String>(
                  value: option['value'],
                  groupValue: _selectedPriority,
                  onChanged: (value) {
                    setState(() => _selectedPriority = value!);
                  },
                  title: Row(
                    children: [
                      Icon(
                        option['icon'],
                        color: option['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(option['label']),
                    ],
                  ),
                  activeColor: option['color'],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor: _selectedPriority == option['value']
                      ? (option['color'] as Color).withOpacity(0.1)
                      : null,
                );
              }),
              
              const SizedBox(height: 24),
              
              // Title field
              Text(
                'Alert Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Scheduled Maintenance',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              
              const SizedBox(height: 16),
              
              // Message field
              Text(
                'Alert Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Enter the alert message details...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.message),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  if (value.trim().length < 10) {
                    return 'Message must be at least 10 characters';
                  }
                  return null;
                },
                maxLines: 6,
                maxLength: 500,
              ),
              
              const SizedBox(height: 24),
              
              // Send button
              ElevatedButton.icon(
                onPressed: _sending ? null : _sendAlert,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _sending ? 'Sending...' : 'Send Alert',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This alert will be sent to all users who have registered ${widget.utilityType} utilities under your authority.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
