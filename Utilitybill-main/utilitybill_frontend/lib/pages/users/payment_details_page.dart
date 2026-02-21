import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';

class SavedPaymentMethod {
  final String method;
  final String detail;
  final DateTime createdAt;

  const SavedPaymentMethod({
    required this.method,
    required this.detail,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'detail': detail,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      method: (json['method'] ?? '').toString(),
      detail: (json['detail'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class PaymentDetailsPage extends StatefulWidget {
  const PaymentDetailsPage({super.key});

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  static const _savedStorageKey = 'saved_payment_methods_v1';
  
  String? _selectedPaymentMethod;
  bool _isEditing = false;
  bool _showAvailableMethods = false;
  
  // Card details
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  
  // Bank details
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  
  // UPI details
  final _upiIdController = TextEditingController();

  List<SavedPaymentMethod> _savedMethods = [];
  bool _loadingSaved = true;

  static const List<String> _paymentMethods = [
    'Credit Card',
    'Bank Transfer',
    'UPI',
  ];

  static const Map<String, IconData> _methodIcons = {
    'Credit Card': Icons.credit_card,
    'Bank Transfer': Icons.account_balance,
    'UPI': Icons.payments,
  };

  @override
  void initState() {
    super.initState();
    _loadSavedMethods();
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _cardHolderController.clear();
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _accountHolderController.clear();
    _accountNumberController.clear();
    _ifscCodeController.clear();
    _bankNameController.clear();
    _branchNameController.clear();
    _upiIdController.clear();
  }

  Future<void> _loadSavedMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedStorageKey);
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() {
        _savedMethods = [];
        _loadingSaved = false;
      });
      return;
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final items = list.map(SavedPaymentMethod.fromJson).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _savedMethods = items;
        _loadingSaved = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savedMethods = [];
        _loadingSaved = false;
      });
    }
  }

  Future<void> _persistSavedMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_savedMethods.map((e) => e.toJson()).toList());
    await prefs.setString(_savedStorageKey, raw);
  }

  void _showAddPaymentMethod() {
    _clearFields();
    setState(() {
      _selectedPaymentMethod = null;
      _isEditing = false;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: _buildPaymentMethodForm(),
          ),
        ),
      ),
    );
  }

  void _showCreditCardForm() {
    _clearFields();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credit Card Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    decoration: InputDecoration(
                      labelText: 'Card Number',
                      prefixIcon: const Icon(Icons.credit_card),
                      hintText: 'XXXX XXXX XXXX XXXX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Card number is required';
                      }
                      if (value.replaceAll(' ', '').length < 13) {
                        return 'Card number must be at least 13 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          decoration: InputDecoration(
                            labelText: 'Expiry Date',
                            prefixIcon: const Icon(Icons.calendar_today),
                            hintText: 'MM/YY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Expiry date is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'CVV is required';
                            }
                            if (value.length < 3) {
                              return 'CVV must be 3-4 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final raw = _cardNumberController.text.replaceAll(' ', '');
                          final last4 = raw.length >= 4
                              ? raw.substring(raw.length - 4)
                              : raw;
                          _savePaymentMethod(
                            method: 'Credit Card',
                            detail: 'Card • ****$last4',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBankTransferForm() {
    _clearFields();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank Transfer Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Account number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ifscCodeController,
                    decoration: InputDecoration(
                      labelText: 'IFSC Code',
                      prefixIcon: const Icon(Icons.code),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'IFSC code is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _branchNameController,
                    decoration: InputDecoration(
                      labelText: 'Branch Name',
                      prefixIcon: const Icon(Icons.account_balance),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Branch name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final acct = _accountNumberController.text.trim();
                          final last4 = acct.length >= 4
                              ? acct.substring(acct.length - 4)
                              : acct;
                          _savePaymentMethod(
                            method: 'Bank Transfer',
                            detail: 'A/C • ****$last4',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUpiForm() {
    _clearFields();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPI Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _upiIdController,
                    decoration: InputDecoration(
                      labelText: 'UPI ID',
                      prefixIcon: const Icon(Icons.mail),
                      hintText: 'yourname@bank',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'UPI ID is required';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid UPI ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _savePaymentMethod(
                            method: 'UPI',
                            detail: _upiIdController.text.trim(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodForm() {
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Payment Method',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment Method Dropdown
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: const Icon(Icons.payment),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: scheme.outline),
              ),
            ),
            items: _paymentMethods
                .map((method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a payment method';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Conditional fields based on selected method
            if (_selectedPaymentMethod == 'Credit Card') ...[
            TextFormField(
              controller: _cardHolderController,
              decoration: InputDecoration(
                labelText: 'Card Holder Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Card holder name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              maxLength: 19,
              decoration: InputDecoration(
                labelText: 'Card Number',
                prefixIcon: const Icon(Icons.credit_card),
                hintText: 'XXXX XXXX XXXX XXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Card number is required';
                }
                if (value.replaceAll(' ', '').length < 13) {
                  return 'Card number must be at least 13 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Expiry date is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'CVV is required';
                      }
                      if (value.length < 3) {
                        return 'CVV must be 3-4 digits';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],

          if (_selectedPaymentMethod == 'Bank Transfer') ...[
            TextFormField(
              controller: _bankNameController,
              decoration: InputDecoration(
                labelText: 'Bank Name',
                prefixIcon: const Icon(Icons.account_balance),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bank name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountHolderController,
              decoration: InputDecoration(
                labelText: 'Account Holder Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Account holder name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Account Number',
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Account number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ifscCodeController,
              decoration: InputDecoration(
                labelText: 'IFSC Code',
                prefixIcon: const Icon(Icons.code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'IFSC code is required';
                }
                return null;
              },
            ),
          ],

          if (_selectedPaymentMethod == 'UPI') ...[
            TextFormField(
              controller: _upiIdController,
              decoration: InputDecoration(
                labelText: 'UPI ID',
                prefixIcon: const Icon(Icons.mail),
                hintText: 'yourname@bank',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'UPI ID is required';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid UPI ID';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final method = _selectedPaymentMethod ?? 'Payment Method';
                      String detail = method;
                      if (method == 'Credit Card') {
                        final raw = _cardNumberController.text.replaceAll(' ', '');
                        final last4 = raw.length >= 4
                            ? raw.substring(raw.length - 4)
                            : raw;
                        detail = 'Card • ****$last4';
                      } else if (method == 'Bank Transfer') {
                        final acct = _accountNumberController.text.trim();
                        final last4 = acct.length >= 4
                            ? acct.substring(acct.length - 4)
                            : acct;
                        detail = 'A/C • ****$last4';
                      } else if (method == 'UPI') {
                        detail = _upiIdController.text.trim();
                      }
                      _savePaymentMethod(method: method, detail: detail);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _savePaymentMethod({
    required String method,
    required String detail,
  }) async {
    final item = SavedPaymentMethod(
      method: method,
      detail: detail,
      createdAt: DateTime.now(),
    );
    setState(() {
      _savedMethods = [item, ..._savedMethods];
    });
    await _persistSavedMethods();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$method saved successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
    setState(() {
      _clearFields();
    });
  }

  String _formatSavedDate(DateTime dt) {
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
                      'Payment Methods',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saved Payment Methods Section
                    Text(
                      'Saved Payment Methods',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingSaved)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_savedMethods.isEmpty)
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
                              Icons.payment_outlined,
                              size: 48,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No saved payment methods yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a payment method to get started',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedMethods.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _savedMethods[index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                _methodIcons[item.method] ?? Icons.payment,
                                color: scheme.primary,
                              ),
                              title: Text(
                                item.method,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(item.detail),
                              trailing: Text(
                                _formatSavedDate(item.createdAt),
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Add New Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAvailableMethods = !_showAvailableMethods;
                          });
                        },
                        icon: Icon(
                          _showAvailableMethods
                              ? Icons.expand_less
                              : Icons.add,
                        ),
                        label: Text(
                          _showAvailableMethods
                              ? 'Hide Payment Methods'
                              : 'Add Payment Method',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (_showAvailableMethods) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Available Payment Methods',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _paymentMethods.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final method = _paymentMethods[index];
                          final icon = _methodIcons[method] ?? Icons.payment;

                          return GestureDetector(
                            onTap: () {
                              if (method == 'Credit Card') {
                                _showCreditCardForm();
                                return;
                              }
                              if (method == 'Bank Transfer') {
                                _showBankTransferForm();
                                return;
                              }
                              if (method == 'UPI') {
                                _showUpiForm();
                                return;
                              }
                              setState(() => _selectedPaymentMethod = method);
                              _showAddPaymentMethod();
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  icon,
                                  size: 32,
                                  color: scheme.primary,
                                ),
                                title: Text(
                                  method,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                  color: scheme.secondary,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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