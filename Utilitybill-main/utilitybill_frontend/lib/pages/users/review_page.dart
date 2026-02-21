import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/theme_header.dart';

class SavedReview {
  final String utilityType;
  final int rating;
  final String message;
  final DateTime createdAt;
  final String username;

  const SavedReview({
    required this.utilityType,
    required this.rating,
    required this.message,
    required this.createdAt,
    required this.username,
  });

  Map<String, dynamic> toJson() => {
        'utilityType': utilityType,
        'rating': rating,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'username': username,
      };

  factory SavedReview.fromJson(Map<String, dynamic> json) {
    return SavedReview(
      utilityType: (json['utilityType'] ?? '').toString(),
      rating: (json['rating'] ?? 0) as int,
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      username: (json['username'] ?? '').toString(),
    );
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  int _rating = 0;
  String? _selectedUtility;
  static const List<String> _utilityOptions = [
    'Electricity',
    'Water',
    'Gas',
    'WiFi',
    'DTH',
    'Others',
  ];
  static const _reviewsStorageKey = 'saved_reviews_v1';
  List<SavedReview> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_username') ?? '';

    final review = SavedReview(
      utilityType: _selectedUtility ?? 'Other',
      rating: _rating,
      message: _messageController.text.trim(),
      createdAt: DateTime.now(),
      username: currentUsername,
    );
    
    // Load all reviews
    final raw = prefs.getString(_reviewsStorageKey);
    List<SavedReview> allReviews = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        allReviews = list.map(SavedReview.fromJson).toList();
      } catch (_) {}
    }
    
    // Add new review to all reviews
    allReviews = [review, ...allReviews];
    
    // Save all reviews
    final encoded = jsonEncode(allReviews.map((e) => e.toJson()).toList());
    await prefs.setString(_reviewsStorageKey, encoded);
    
    // Update displayed reviews (filtered by current user)
    setState(() {
      _reviews = [review, ..._reviews];
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your review!')),
    );
    _messageController.clear();
    setState(() {
      _rating = 0;
      _selectedUtility = null;
    });
  }

  Future<void> _loadReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_username') ?? '';
    final raw = prefs.getString(_reviewsStorageKey);
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _loadingReviews = false;
      });
      return;
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final allReviews = list.map(SavedReview.fromJson).toList();
      
      // Filter reviews to show only current user's reviews
      final userReviews = allReviews
          .where((review) => review.username == currentUsername)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (!mounted) return;
      setState(() {
        _reviews = userReviews;
        _loadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _loadingReviews = false;
      });
    }
  }

  Future<void> _deleteReview(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Load all reviews
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewsStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final allReviews = list.map(SavedReview.fromJson).toList();
      
      // Find and remove the review
      final reviewToDelete = _reviews[index];
      allReviews.removeWhere((r) => 
        r.username == reviewToDelete.username &&
        r.utilityType == reviewToDelete.utilityType &&
        r.rating == reviewToDelete.rating &&
        r.message == reviewToDelete.message &&
        r.createdAt == reviewToDelete.createdAt
      );

      // Save updated reviews
      final encoded = jsonEncode(allReviews.map((e) => e.toJson()).toList());
      await prefs.setString(_reviewsStorageKey, encoded);

      // Update UI
      setState(() {
        _reviews.removeAt(index);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete review')),
      );
    }
  }

  Future<void> _editReview(int index) async {
    final review = _reviews[index];
    final editMessageController = TextEditingController(text: review.message);
    String? editUtility = review.utilityType;
    int editRating = review.rating;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: editUtility,
                  decoration: const InputDecoration(labelText: 'Utility Type'),
                  items: _utilityOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => editUtility = value),
                ),
                const SizedBox(height: 16),
                const Text('Rating:'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < editRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setDialogState(() => editRating = i + 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: editMessageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'utilityType': editUtility,
                  'rating': editRating,
                  'message': editMessageController.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    editMessageController.dispose();

    if (result == null) return;

    // Load all reviews
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_username') ?? '';
    final raw = prefs.getString(_reviewsStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final allReviews = list.map(SavedReview.fromJson).toList();
      
      // Find and update the review
      final reviewToEdit = _reviews[index];
      final reviewIndex = allReviews.indexWhere((r) => 
        r.username == reviewToEdit.username &&
        r.utilityType == reviewToEdit.utilityType &&
        r.rating == reviewToEdit.rating &&
        r.message == reviewToEdit.message &&
        r.createdAt == reviewToEdit.createdAt
      );

      if (reviewIndex != -1) {
        allReviews[reviewIndex] = SavedReview(
          utilityType: result['utilityType'],
          rating: result['rating'],
          message: result['message'],
          createdAt: reviewToEdit.createdAt,
          username: currentUsername,
        );
      }

      // Save updated reviews
      final encoded = jsonEncode(allReviews.map((e) => e.toJson()).toList());
      await prefs.setString(_reviewsStorageKey, encoded);

      // Reload reviews
      await _loadReviews();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update review')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: Column(
          children: [
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
                      'Reviews',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose utility type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedUtility,
                        decoration: InputDecoration(
                          labelText: 'Utility Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: scheme.outline),
                          ),
                        ),
                        items: _utilityOptions
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedUtility = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a utility type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Rate your experience',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          return IconButton(
                            onPressed: () => setState(() => _rating = starIndex),
                            icon: Icon(
                              _rating >= starIndex
                                  ? Icons.star
                                  : Icons.star_border,
                              color: _rating >= starIndex
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Write a review',
                          hintText: 'Share your feedback...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: scheme.outline),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your review';
                          }
                          if (value.trim().length < 10) {
                            return 'Review should be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitReview,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Submit Review'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Your Reviews',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingReviews)
                        const Center(child: CircularProgressIndicator())
                      else if (_reviews.isEmpty)
                        Text(
                          'No reviews yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        review.utilityType,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < review.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(review.message),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(review.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      color: scheme.primary,
                                      onPressed: () => _editReview(index),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: Colors.red,
                                      onPressed: () => _deleteReview(index),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
