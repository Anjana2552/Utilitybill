import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';

class UtilityReviewsPage extends StatefulWidget {
  final String providerName;
  const UtilityReviewsPage({super.key, required this.providerName});

  @override
  State<UtilityReviewsPage> createState() => _UtilityReviewsPageState();
}

class _UtilityReviewsPageState extends State<UtilityReviewsPage> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    final utilityType = _utilityTypeForProvider(widget.providerName);
    
    try {
      // Load from database via API
      final queryParams = <String, String>{};
      if (widget.providerName.isNotEmpty) {
        queryParams['provider_name'] = widget.providerName;
      }
      if (utilityType != null) {
        queryParams['utility_type'] = utilityType;
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/reviews/list/').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reviewsList = (data['reviews'] as List<dynamic>?) ?? [];
        
        final List<Map<String, dynamic>> reviews = reviewsList.map((item) {
          final reviewData = item as Map<String, dynamic>;
          return {
            'utilityType': (reviewData['utility_type'] ?? '').toString(),
            'rating': (reviewData['rating'] ?? 0) as int,
            'message': (reviewData['message'] ?? '').toString(),
            'createdAt': (reviewData['created_at'] ?? '').toString(),
            'username': (reviewData['username'] ?? '').toString(),
          };
        }).toList();
        
        reviews.sort((a, b) {
          final aDt = DateTime.tryParse((a['createdAt'] ?? '').toString()) ?? DateTime(1970);
          final bDt = DateTime.tryParse((b['createdAt'] ?? '').toString()) ?? DateTime(1970);
          return bDt.compareTo(aDt);
        });
        
        if (!mounted) return;
        setState(() {
          _reviews = reviews;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _reviews = [];
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _loading = false;
      });
    }
  }

  String? _utilityTypeForProvider(String provider) {
    final p = provider.toLowerCase();
    if (p == 'kseb') return 'Electricity';
    if (p == 'water' || p == 'kwa') return 'Water';
    if (p == 'gas') return 'Gas';
    if (p == 'wifi') return 'WiFi';
    if (p == 'dth') return 'DTH';
    if (p == 'others' || p == 'other') return 'Others';
    return null;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Reviews',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_reviews.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outline),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 48,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reviews available yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'New reviews will appear here.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = _reviews[index];
                          final rating = (r['rating'] ?? 0) as int;
                          final msg = (r['message'] ?? '').toString();
                          final type = (r['utilityType'] ?? '').toString();
                          final dt = DateTime.tryParse((r['createdAt'] ?? '').toString()) ?? DateTime.now();
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                type.isEmpty ? 'Review' : type,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(msg),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 14,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(dt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant,
                                    ),
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
          ],
        ),
      ),
    );
  }
}
