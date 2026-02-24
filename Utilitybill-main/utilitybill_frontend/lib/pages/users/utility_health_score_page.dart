import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../../config/api_config.dart';

class UtilityHealthScorePage extends StatefulWidget {
  const UtilityHealthScorePage({super.key});

  @override
  State<UtilityHealthScorePage> createState() => _UtilityHealthScorePageState();
}

class _UtilityHealthScorePageState extends State<UtilityHealthScorePage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  int _healthScore = 0;
  String _healthRating = 'Good';
  Color _healthColor = Colors.green;
  
  int _totalBills = 0;
  int _paidBills = 0;
  int _pendingBills = 0;
  int _overdueBills = 0;
  int _earlyPayments = 0;
  int _onTimePayments = 0;
  int _latePayments = 0;
  double _totalPaid = 0.0;
  double _totalPending = 0.0;
  double _walletBalance = 0.0;
  
  // Monthly limit feature
  double _monthlyLimit = 0.0;
  double _currentMonthSpending = 0.0;
  
  Map<String, int> _utilityBreakdown = {};
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _loadHealthData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    setState(() => _loading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      
      // Load monthly limit from preferences
      _monthlyLimit = prefs.getDouble('monthly_limit') ?? 0.0;
      
      if (username.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Fetch user utilities
      final utilUri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}',
      );
      final utilResp = await http.get(utilUri);
      
      if (utilResp.statusCode == 200) {
        final utilData = jsonDecode(utilResp.body) as Map<String, dynamic>;
        final utilities = (utilData['results'] as List<dynamic>?) ?? [];
        
        // Fetch bills for each utility
        for (final utility in utilities) {
          final utilityType = (utility['utility_type'] ?? '').toString();
          String consumerId = '';
          
          if (utilityType.toLowerCase() == 'electricity') {
            consumerId = (utility['consumer_number'] ?? '').toString();
          } else if (utilityType.toLowerCase() == 'water') {
            consumerId = (utility['water_connection_number'] ?? '').toString();
          } else if (utilityType.toLowerCase() == 'gas') {
            consumerId = (utility['gas_connection_number'] ?? '').toString();
          } else if (utilityType.toLowerCase() == 'wifi' || 
                     utilityType.toLowerCase() == 'internet') {
            consumerId = (utility['wifi_consumer_id'] ?? '').toString();
          } else if (utilityType.toLowerCase() == 'dth') {
            consumerId = (utility['dth_subscriber_id'] ?? '').toString();
          }
          
          if (consumerId.isNotEmpty) {
            await _fetchBillsForUtility(consumerId, utilityType);
          }
        }
      }
      
      // Fetch wallet balance
      final walletUri = Uri.parse(
        '${ApiConfig.baseUrl}/wallet/balance/?username=${Uri.encodeQueryComponent(username)}',
      );
      final walletResp = await http.get(walletUri);
      
      if (walletResp.statusCode == 200) {
        final walletData = jsonDecode(walletResp.body) as Map<String, dynamic>;
        _walletBalance = double.tryParse(
          (walletData['balance'] ?? '0').toString()
        ) ?? 0.0;
      }
      
      // Calculate current month spending
      // Note: _currentMonthSpending is already calculated in _fetchBillsForUtility
      
      // Verify counts (total should equal paid + pending + overdue)
      print('=== Health Score Data Verification ===');
      print('Total Bills: $_totalBills');
      print('Paid Bills: $_paidBills');
      print('Pending Bills: $_pendingBills');
      print('Overdue Bills: $_overdueBills');
      print('Verification: ${_paidBills + _pendingBills + _overdueBills} should equal $_totalBills');
      print('Payment Timing - Early: $_earlyPayments, On-time: $_onTimePayments, Late: $_latePayments');
      print('Current Month Spending: ₹${_currentMonthSpending.toStringAsFixed(2)}');
      print('Monthly Limit: ₹${_monthlyLimit.toStringAsFixed(2)}');
      print('=====================================');
      
      // Calculate health score
      _calculateHealthScore();
      _animationController.forward();
      
      // Check monthly limit and create notifications if needed
      if (_monthlyLimit > 0) {
        await _checkMonthlyLimitAndNotify(username);
      }
      
      setState(() => _loading = false);
    } catch (e) {
      print('Error loading health data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchBillsForUtility(String consumerId, String utilityType) async {
    try {
      final billsUri = Uri.parse(
        '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(consumerId)}',
      );
      final billsResp = await http.get(billsUri);
      
      if (billsResp.statusCode == 200) {
        final billsData = jsonDecode(billsResp.body) as Map<String, dynamic>;
        final bills = (billsData['results'] as List<dynamic>?) ?? [];
        
        for (final bill in bills) {
          _totalBills++;
          final status = (bill['bill_status'] ?? 'unpaid').toString().toLowerCase();
          final amount = double.tryParse((bill['total_amount'] ?? '0').toString()) ?? 0.0;
          final billId = (bill['bill_id'] ?? '').toString();
          
          // Count utility breakdown
          _utilityBreakdown[utilityType] = (_utilityBreakdown[utilityType] ?? 0) + 1;
          
          if (status == 'paid') {
            _paidBills++;
            _totalPaid += amount;
            
            // Check payment timing for paid bills
            await _checkPaymentTiming(billId, bill);
          } else {
            // Unpaid bill - check if overdue or pending
            _totalPending += amount;
            
            // Check if bill is for current month and if overdue
            final dueDateStr = bill['due_date'];
            bool isOverdue = false;
            
            if (dueDateStr != null) {
              try {
                final dueDate = DateTime.parse(dueDateStr.toString());
                final now = DateTime.now();
                
                // Add to current month spending if due date is in current month
                if (dueDate.year == now.year && dueDate.month == now.month) {
                  _currentMonthSpending += amount;
                }
                
                // Set time to end of day for due date comparison
                final dueDateEndOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
                
                if (now.isAfter(dueDateEndOfDay)) {
                  _overdueBills++;
                  isOverdue = true;
                }
              } catch (e) {
                print('Error parsing due_date: $e');
              }
            }
            
            // If not overdue, count as pending
            if (!isOverdue) {
              _pendingBills++;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching bills for $utilityType: $e');
    }
  }

  Future<void> _checkPaymentTiming(String billId, Map<String, dynamic> bill) async {
    try {
      // Fetch payment details for this bill
      final paymentUri = Uri.parse(
        '${ApiConfig.baseUrl}/payments/list/?bill_id=${Uri.encodeQueryComponent(billId)}',
      );
      final paymentResp = await http.get(paymentUri);
      
      if (paymentResp.statusCode == 200) {
        final paymentData = jsonDecode(paymentResp.body) as Map<String, dynamic>;
        final payments = (paymentData['results'] as List<dynamic>?) ?? [];
        
        if (payments.isNotEmpty) {
          // Get the first approved payment
          final payment = payments.firstWhere(
            (p) => (p['status'] ?? '').toString().toLowerCase() == 'approved',
            orElse: () => payments.first,
          );
          
          final paymentDateStr = payment['payment_date'];
          final dueDateStr = bill['due_date'];
          
          if (paymentDateStr != null && dueDateStr != null) {
            try {
              final paymentDate = DateTime.parse(paymentDateStr.toString());
              final dueDate = DateTime.parse(dueDateStr.toString());
              
              // Calculate days difference
              final daysDifference = dueDate.difference(paymentDate).inDays;
              
              if (daysDifference > 5) {
                // Paid more than 5 days before due date - Early payment
                _earlyPayments++;
              } else if (daysDifference >= 0) {
                // Paid on the due date or within 5 days before - On time
                _onTimePayments++;
              } else {
                // Paid after due date - Late payment
                _latePayments++;
              }
            } catch (e) {
              print('Error parsing dates: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error checking payment timing: $e');
    }
  }

  void _calculateHealthScore() {
    // Start with base score of 100
    int score = 100;
    
    // REWARD SYSTEM - Add points for good payment behavior
    
    // +3 points for each early payment (paid >5 days before due date)
    if (_earlyPayments > 0) {
      score += (_earlyPayments * 3);
    }
    
    // +2 points for each on-time payment (paid 0-5 days before or on due date)
    if (_onTimePayments > 0) {
      score += (_onTimePayments * 2);
    }
    
    // Bonus for consistent payment pattern (max +15)
    if (_paidBills > 0) {
      final onTimeRatio = (_earlyPayments + _onTimePayments) / _paidBills;
      if (onTimeRatio >= 0.9) {
        score += 15; // 90%+ on-time/early
      } else if (onTimeRatio >= 0.7) {
        score += 10; // 70%+ on-time/early
      } else if (onTimeRatio >= 0.5) {
        score += 5; // 50%+ on-time/early
      }
    }
    
    // PENALTY SYSTEM - Deduct points for poor payment behavior
    
    // -5 points for each late payment (paid after due date)
    if (_latePayments > 0) {
      score -= (_latePayments * 5);
    }
    
    // Deduct points for pending bills (max -20)
    if (_totalBills > 0) {
      final pendingRatio = _pendingBills / _totalBills;
      score -= (pendingRatio * 20).round();
    }
    
    // Deduct more points for overdue bills (max -35)
    if (_totalBills > 0) {
      final overdueRatio = _overdueBills / _totalBills;
      score -= (overdueRatio * 35).round();
    }
    
    // Extra penalty for overdue bills (flat deduction)
    if (_overdueBills > 0) {
      score -= (_overdueBills * 3);
    }
    
    // Deduct points for low wallet balance (max -15)
    if (_totalPending > 0) {
      final balanceRatio = _walletBalance / _totalPending;
      if (balanceRatio < 0.3) {
        score -= 15; // Less than 30% of pending amount
      } else if (balanceRatio < 0.5) {
        score -= 10; // Less than 50% of pending amount
      } else if (balanceRatio < 0.8) {
        score -= 5; // Less than 80% of pending amount
      }
    }
    
    // Bonus for maintaining sufficient wallet balance (max +5)
    if (_totalPending > 0 && _walletBalance >= _totalPending * 1.5) {
      score += 5; // Wallet has 150%+ of pending amount
    }
    
    // Ensure score is between 0 and 150 (allowing rewards to go above 100)
    _healthScore = math.max(0, math.min(150, score));
    
    // Determine rating and color based on score
    if (_healthScore >= 120) {
      _healthRating = 'Outstanding';
      _healthColor = Color(0xFF1B5E20); // Dark green
    } else if (_healthScore >= 100) {
      _healthRating = 'Excellent';
      _healthColor = Colors.green;
    } else if (_healthScore >= 80) {
      _healthRating = 'Very Good';
      _healthColor = Colors.lightGreen;
    } else if (_healthScore >= 60) {
      _healthRating = 'Good';
      _healthColor = Color(0xFF7CB342); // Light green
    } else if (_healthScore >= 40) {
      _healthRating = 'Fair';
      _healthColor = Colors.orange;
    } else if (_healthScore >= 20) {
      _healthRating = 'Poor';
      _healthColor = Colors.deepOrange;
    } else {
      _healthRating = 'Critical';
      _healthColor = Colors.red;
    }
  }

  Future<void> _setMonthlyLimit() async {
    final controller = TextEditingController(
      text: _monthlyLimit > 0 ? _monthlyLimit.toStringAsFixed(0) : '',
    );
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your monthly utility spending limit to track your budget.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monthly Limit',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter amount',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null && result >= 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('monthly_limit', result);
      
      setState(() {
        _monthlyLimit = result;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monthly limit set to ₹${result.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _checkMonthlyLimitAndNotify(String username) async {
    try {
      // Only check if monthly limit is set and there's spending
      if (_monthlyLimit <= 0 || _currentMonthSpending <= 0) {
        return;
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/budget/check-monthly-limit/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'monthly_limit': _monthlyLimit,
          'current_month_spending': _currentMonthSpending,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[BUDGET CHECK] ${data['message']}');
        
        // Show in-app notification if budget exceeded
        if (data['status'] == 'exceeded' && mounted) {
          final overAmount = data['over_amount'] ?? 0.0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Budget exceeded by ₹${overAmount.toStringAsFixed(2)}!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  // Scroll to budget card (already visible on this page)
                },
              ),
            ),
          );
        } else if (data['status'] == 'nearing_limit' && mounted) {
          final remaining = data['remaining'] ?? 0.0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nearing budget limit! ₹${remaining.toStringAsFixed(2)} remaining',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (data['status'] == 'within_budget' && mounted) {
          final remaining = data['remaining'] ?? 0.0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Within budget! ₹${remaining.toStringAsFixed(2)} remaining',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking monthly limit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Utility Health Score'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHealthData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Health Score Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _healthColor.withOpacity(0.8),
                              _healthColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              'Your Health Score',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedBuilder(
                              animation: _scoreAnimation,
                              builder: (context, child) {
                                final displayScore = (_scoreAnimation.value * _healthScore).round();
                                final progressValue = math.min(1.0, displayScore / 100.0);
                                
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: CircularProgressIndicator(
                                        value: progressValue,
                                        strokeWidth: 12,
                                        backgroundColor: Colors.white.withOpacity(0.3),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$displayScore',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_healthScore > 100)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.trending_up,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '+${_healthScore - 100}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _healthRating,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Based on payment history, pending bills, and wallet balance',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Payment Timing Stats (New Section)
                    if (_paidBills > 0) ...[
                      Card(
                        elevation: 2,
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
                                  Icon(Icons.timer_outlined, 
                                    color: Colors.blue.shade700, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payment Timing Analysis',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Early Payments
                              _PaymentTimingRow(
                                icon: Icons.flash_on,
                                iconColor: Colors.green,
                                label: 'Early Payments',
                                count: _earlyPayments,
                                description: 'Paid >5 days early',
                                points: '+${_earlyPayments * 3} pts',
                              ),
                              const Divider(height: 20),
                              
                              // On-Time Payments
                              _PaymentTimingRow(
                                icon: Icons.check_circle,
                                iconColor: Colors.lightGreen,
                                label: 'On-Time Payments',
                                count: _onTimePayments,
                                description: 'Paid before or on due date',
                                points: '+${_onTimePayments * 2} pts',
                              ),
                              const Divider(height: 20),
                              
                              // Late Payments
                              _PaymentTimingRow(
                                icon: Icons.warning,
                                iconColor: Colors.red,
                                label: 'Late Payments',
                                count: _latePayments,
                                description: 'Paid after due date',
                                points: '-${_latePayments * 5} pts',
                              ),
                              
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, 
                                      size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Pay early to earn bonus points and improve your score!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade900,
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
                      const SizedBox(height: 20),
                    ],
                    
                    // Monthly Limit Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: _setMonthlyLimit,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _monthlyLimit > 0
                                  ? [Colors.blue.shade700, Colors.blue.shade900]
                                  : [Colors.grey.shade600, Colors.grey.shade800],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Monthly Budget',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_monthlyLimit > 0) ...[
                                // Show budget progress
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pending This Month',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${_currentMonthSpending.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Budget',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${_monthlyLimit.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Progress bar
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _monthlyLimit > 0
                                            ? math.min(1.0, _currentMonthSpending / _monthlyLimit)
                                            : 0,
                                        minHeight: 8,
                                        backgroundColor: Colors.white.withOpacity(0.3),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _currentMonthSpending > _monthlyLimit
                                              ? Colors.red
                                              : _currentMonthSpending > _monthlyLimit * 0.8
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _currentMonthSpending > _monthlyLimit
                                              ? 'Over budget!'
                                              : _currentMonthSpending > _monthlyLimit * 0.8
                                                  ? 'Nearing limit'
                                                  : 'Within budget',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${(_monthlyLimit > 0 ? (_currentMonthSpending / _monthlyLimit * 100) : 0).toStringAsFixed(0)}% used',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // No limit set
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tap to set your monthly utility spending limit',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long,
                            title: 'Total Bills',
                            value: '$_totalBills',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle,
                            title: 'Paid',
                            value: '$_paidBills',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.pending_actions,
                            title: 'Pending',
                            value: '$_pendingBills',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.warning,
                            title: 'Overdue',
                            value: '$_overdueBills',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    
                    // Verification indicator
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (_paidBills + _pendingBills + _overdueBills == _totalBills)
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_paidBills + _pendingBills + _overdueBills == _totalBills)
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (_paidBills + _pendingBills + _overdueBills == _totalBills)
                                ? Icons.verified
                                : Icons.error_outline,
                            size: 16,
                            color: (_paidBills + _pendingBills + _overdueBills == _totalBills)
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (_paidBills + _pendingBills + _overdueBills == _totalBills)
                                ? 'Verified: $_paidBills + $_pendingBills + $_overdueBills = $_totalBills'
                                : 'Error: Total mismatch',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: (_paidBills + _pendingBills + _overdueBills == _totalBills)
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Payment Summary
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SummaryRow(
                              label: 'Total Paid',
                              value: '₹${_totalPaid.toStringAsFixed(2)}',
                              valueColor: Colors.green,
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              label: 'Total Pending',
                              value: '₹${_totalPending.toStringAsFixed(2)}',
                              valueColor: Colors.orange,
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              label: 'Wallet Balance',
                              value: '₹${_walletBalance.toStringAsFixed(2)}',
                              valueColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Utility Breakdown
                    if (_utilityBreakdown.isNotEmpty) ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Utility Breakdown',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._utilityBreakdown.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getUtilityIcon(entry.key),
                                        color: _getUtilityColor(entry.key),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getUtilityColor(entry.key)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${entry.value} bills',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getUtilityColor(entry.key),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Tips Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Tips to Improve Your Score',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_overdueBills > 0)
                              _TipItem('Pay overdue bills immediately to avoid penalties'),
                            if (_pendingBills > 0)
                              _TipItem('Clear pending bills before due dates'),
                            if (_latePayments > 0)
                              _TipItem('Try to pay bills at least 5 days before due date for bonus points'),
                            if (_walletBalance < _totalPending)
                              _TipItem('Top up your wallet to cover pending bills'),
                            if (_healthScore >= 100)
                              _TipItem('Outstanding! Keep paying your bills early to maintain your excellent score'),
                            if (_healthScore >= 80 && _healthScore < 100)
                              _TipItem('Great job! Pay bills early to reach 100+ score'),
                            if (_earlyPayments > 0 && _earlyPayments >= _paidBills * 0.5)
                              _TipItem('Excellent payment timing! You\'re earning bonus points'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getUtilityIcon(String utilityType) {
    switch (utilityType.toLowerCase()) {
      case 'electricity':
        return Icons.electric_bolt;
      case 'water':
        return Icons.water_drop;
      case 'gas':
        return Icons.local_fire_department;
      case 'wifi':
      case 'internet':
        return Icons.wifi;
      case 'dth':
        return Icons.tv;
      default:
        return Icons.category;
    }
  }

  Color _getUtilityColor(String utilityType) {
    switch (utilityType.toLowerCase()) {
      case 'electricity':
        return Colors.amber;
      case 'water':
        return Colors.blue;
      case 'gas':
        return Colors.deepOrange;
      case 'wifi':
      case 'internet':
        return Colors.purple;
      case 'dth':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTimingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final String description;
  final String points;

  const _PaymentTimingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.description,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      points,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
