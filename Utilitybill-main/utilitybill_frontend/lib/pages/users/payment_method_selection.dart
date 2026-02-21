import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class SavedPaymentMethod {
  final String method;
  final String detail;
  final DateTime createdAt;

  const SavedPaymentMethod({
    required this.method,
    required this.detail,
    required this.createdAt,
  });

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      method: (json['method'] ?? '').toString(),
      detail: (json['detail'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class PaymentMethodSelectionPage extends StatefulWidget {
  const PaymentMethodSelectionPage({super.key});

  @override
  State<PaymentMethodSelectionPage> createState() => _PaymentMethodSelectionPageState();
}

class _PaymentMethodSelectionPageState extends State<PaymentMethodSelectionPage> {
  String? _selectedKey;
  final _cardFormKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  
  final _bankTransferFormKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderController = TextEditingController();
  
  final _upiFormKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  
  List<SavedPaymentMethod> _savedMethods = [];
  bool _loadingSaved = true;
  String _walletBalance = '0.00';
  bool _loadingWallet = true;

  // key: label
  final Map<String, String> _options = const {
    'wallet': 'My Wallet',
    'credit_card': 'Credit Card',
    'bank_transfer': 'Bank Transfer',
    'upi': 'UPI Payment',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedMethods();
    _loadWalletBalance();
  }

  Future<void> _loadSavedMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('saved_payment_methods_v1');
      if (raw == null || raw.isEmpty) {
        setState(() {
          _savedMethods = [];
          _loadingSaved = false;
        });
        return;
      }
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final methods = list.map(SavedPaymentMethod.fromJson).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _savedMethods = methods;
        _loadingSaved = false;
      });
    } catch (_) {
      setState(() {
        _savedMethods = [];
        _loadingSaved = false;
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() {
          _walletBalance = '0.00';
          _loadingWallet = false;
        });
        return;
      }
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/wallet/balance/?username=${Uri.encodeQueryComponent(username)}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final obj = jsonDecode(resp.body) as Map<String, dynamic>;
        final bal = (obj['balance'] ?? '0.00').toString();
        setState(() {
          _walletBalance = bal;
          _loadingWallet = false;
        });
      } else {
        setState(() {
          _walletBalance = '0.00';
          _loadingWallet = false;
        });
      }
    } catch (_) {
      setState(() {
        _walletBalance = '0.00';
        _loadingWallet = false;
      });
    }
  }

  String _methodForKey(String key) {
    switch (key) {
      case 'wallet':
        return 'wallet';
      case 'credit_card':
        return 'credit_card';
      case 'bank_transfer':
        return 'bank_transfer';
      case 'upi':
        return 'upi';
      default:
        return 'other';
    }
  }

  Icon _iconForKey(String key) {
    final scheme = Theme.of(context).colorScheme;
    switch (key) {
      case 'wallet':
        return Icon(Icons.account_balance_wallet, color: scheme.primary);
      case 'credit_card':
        return Icon(Icons.credit_card, color: scheme.primary);
      case 'bank_transfer':
        return Icon(Icons.account_balance, color: scheme.primary);
      case 'upi':
        return Icon(Icons.payment, color: scheme.primary);
      default:
        return Icon(Icons.payment, color: scheme.primary);
    }
  }

  List<SavedPaymentMethod> _getSavedMethodsForKey(String key) {
    switch (key) {
      case 'credit_card':
        return _savedMethods.where((m) => m.method == 'Credit Card').toList();
      case 'bank_transfer':
        return _savedMethods.where((m) => m.method == 'Bank Transfer').toList();
      case 'upi':
        return _savedMethods.where((m) => m.method == 'UPI').toList();
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _savePaymentMethod(String method, String detail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newMethod = {
        'method': method,
        'detail': detail,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      final raw = prefs.getString('saved_payment_methods_v1');
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        list = jsonDecode(raw) as List<dynamic>;
      }
      list.add(newMethod);
      await prefs.setString('saved_payment_methods_v1', jsonEncode(list));
      await _loadSavedMethods();
    } catch (_) {
      // Error saving
    }
  }

  void _showCreditCardForm() {
    _cardNumberController.clear();
    _expiryDateController.clear();
    _cvvController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _cardFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credit Card Details',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'XXXX XXXX XXXX XXXX',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = (value ?? '').replaceAll(' ', '');
                  if (v.isEmpty) return 'Card number is required';
                  if (v.length < 13) return 'Enter a valid card number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final v = value ?? '';
                        if (v.isEmpty) return 'Expiry date is required';
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) {
                          return 'Use MM/YY format';
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
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final v = value ?? '';
                        if (v.isEmpty) return 'CVV is required';
                        if (v.length < 3) return 'Enter a valid CVV';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_cardFormKey.currentState!.validate()) {
                      final cardNumber = _cardNumberController.text.trim();
                      final lastFour = cardNumber.replaceAll(' ', '').substring(cardNumber.length - 4);
                      await _savePaymentMethod('Credit Card', 'Card • ****$lastFour');
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Card saved successfully')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankTransferForm() {
    _accountNumberController.clear();
    _ifscCodeController.clear();
    _accountHolderController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _bankTransferFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Transfer Details',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountHolderController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value ?? '';
                  if (v.isEmpty) return 'Account number is required';
                  if (v.length < 9) return 'Enter a valid account number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ifscCodeController,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value ?? '';
                  if (v.isEmpty) return 'IFSC code is required';
                  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v.toUpperCase())) {
                    return 'Enter a valid IFSC code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_bankTransferFormKey.currentState!.validate()) {
                      final accountNumber = _accountNumberController.text.trim();
                      final lastFour = accountNumber.substring(accountNumber.length - 4);
                      final holderName = _accountHolderController.text.trim();
                      await _savePaymentMethod('Bank Transfer', '$holderName • ****$lastFour');
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bank account saved successfully')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpiForm() {
    _upiIdController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _upiFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPI Details',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _upiIdController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'username@bankname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value ?? '';
                  if (v.isEmpty) return 'UPI ID is required';
                  if (!v.contains('@')) return 'Enter a valid UPI ID';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_upiFormKey.currentState!.validate()) {
                      final upiId = _upiIdController.text.trim();
                      await _savePaymentMethod('UPI', upiId);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID saved successfully')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select payment method'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Preferred method with secure transactions.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final key = _options.keys.elementAt(idx);
                final label = _options[key]!;
                final selected = _selectedKey == key;
                final savedMethods = _getSavedMethodsForKey(key);
                final showSaved = selected && savedMethods.isNotEmpty;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _selectedKey = key);
                        if (savedMethods.isEmpty) {
                          if (key == 'credit_card') {
                            _showCreditCardForm();
                          } else if (key == 'bank_transfer') {
                            _showBankTransferForm();
                          } else if (key == 'upi') {
                            _showUpiForm();
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? scheme.primary : scheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            _iconForKey(key),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  if (key == 'wallet' && !_loadingWallet)
                                    Text(
                                      'Balance: ₹ $_walletBalance',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (selected)
                              Container(
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.check, color: Colors.white, size: 18),
                              )
                            else
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  border: Border.all(color: scheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (showSaved) ...[
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.only(left: 48, right: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saved ${savedMethods[0].method} Details:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...savedMethods.take(3).map((method) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                method.detail,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedKey == null
                        ? null
                        : () => Navigator.pop(context, _methodForKey(_selectedKey!)),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
