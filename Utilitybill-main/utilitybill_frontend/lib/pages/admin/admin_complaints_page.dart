import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _complaints = [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/complaints/list/');
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final complaints = (data['complaints'] as List<dynamic>?) ?? [];
        setState(() {
          _complaints = complaints.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load complaints: $e')),
        );
      }
    }
  }

  Future<void> _showReplyDialog(Map<String, dynamic> complaint) async {
    final responseController = TextEditingController(
      text: complaint['response'] ?? '',
    );
    String selectedStatus = complaint['status'] ?? 'pending';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reply to ${complaint['username']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subject: ${complaint['subject']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Category: ${complaint['category']}'),
                const SizedBox(height: 8),
                Text('Description:'),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(complaint['description'] ?? 'No description'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: responseController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Response',
                    border: OutlineInputBorder(),
                    hintText: 'Type your response here...',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'status': selectedStatus,
                  'response': responseController.text.trim(),
                });
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _updateComplaint(
        complaint['id'],
        result['status']!,
        result['response']!,
      );
    }
  }

  Future<void> _updateComplaint(
      dynamic id, String status, String response) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/complaints/update/$id/');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'response': response,
        }),
      );

      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Complaint updated successfully'),
                backgroundColor: Colors.green),
          );
        }
        await _loadComplaints();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update complaint')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_statusFilter == null) return _complaints;
    return _complaints
        .where((c) => c['status'] == _statusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredComplaints;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Manage Complaints'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (value) {
              setState(() => _statusFilter = value == 'all' ? null : value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(
                  value: 'in_progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'resolved', child: Text('Resolved')),
              const PopupMenuItem(value: 'closed', child: Text('Closed')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadComplaints,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _statusFilter == null
                              ? 'No complaints yet'
                              : 'No ${_formatStatus(_statusFilter!).toLowerCase()} complaints',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final complaint = filtered[index];
                      final status = complaint['status'] ?? 'pending';
                      final hasResponse =
                          (complaint['response'] ?? '').toString().isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status),
                            child: const Icon(Icons.report_problem,
                                color: Colors.white, size: 20),
                          ),
                          title: Text(
                            complaint['subject'] ?? 'No subject',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('By: ${complaint['username']}'),
                              Text(
                                'Category: ${complaint['category']}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatStatus(status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                  if (hasResponse) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Replied',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Description:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      complaint['description'] ??
                                          'No description',
                                    ),
                                  ),
                                  if (hasResponse) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Admin Response:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green.shade200),
                                      ),
                                      child: Text(complaint['response'] ?? ''),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showReplyDialog(complaint),
                                          icon: const Icon(Icons.reply),
                                          label: Text(hasResponse
                                              ? 'Update Reply'
                                              : 'Reply'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Submitted: ${complaint['created_at'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (complaint['updated_at'] !=
                                      complaint['created_at'])
                                    Text(
                                      'Updated: ${complaint['updated_at'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
