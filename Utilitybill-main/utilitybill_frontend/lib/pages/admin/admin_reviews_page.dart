import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  static const _reviewsStorageKey = 'saved_reviews_v1';
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewsStorageKey);
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _loading = false;
      });
      return;
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      list.sort((a, b) {
        final aDt = DateTime.tryParse((a['createdAt'] ?? '').toString()) ?? DateTime(1970);
        final bDt = DateTime.tryParse((b['createdAt'] ?? '').toString()) ?? DateTime(1970);
        return bDt.compareTo(aDt);
      });
      if (!mounted) return;
      setState(() {
        _reviews = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _loading = false;
      });
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
      appBar: AppBar(
        title: const Text('All User Reviews'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 80,
                        color: scheme.onBackground.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: scheme.onBackground.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final usernameRaw = (review['username'] ?? '').toString().trim();
                      final username = usernameRaw.isEmpty ? 'Anonymous (Legacy)' : usernameRaw;
                      final utilityType = (review['utilityType'] ?? 'N/A').toString();
                      final rating = (review['rating'] ?? 0) as int;
                      final message = (review['message'] ?? '').toString();
                      final createdAt = DateTime.tryParse(
                            (review['createdAt'] ?? '').toString(),
                          ) ??
                          DateTime.now();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: scheme.primary,
                                    child: Text(
                                      username.isNotEmpty
                                          ? username[0].toUpperCase()
                                          : 'A',
                                      style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.category_outlined,
                                              size: 16,
                                              color: scheme.onBackground
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              utilityType,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: scheme.onBackground
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: i < rating
                                                ? Colors.amber
                                                : scheme.onBackground
                                                    .withOpacity(0.3),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onBackground
                                                  .withOpacity(0.5),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (message.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceVariant.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
