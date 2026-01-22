import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/theme_header.dart';
import '../../config/api_config.dart';

class GenerateBillPage extends StatefulWidget {
  const GenerateBillPage({super.key});

  @override
  State<GenerateBillPage> createState() => _GenerateBillPageState();
}

class _GenerateBillPageState extends State<GenerateBillPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _billIdCtrl = TextEditingController();
  String _utilityType = 'Electricity';
  String? _selectedConsumerName;
  final _consumerNumberCtrl = TextEditingController();
  final _prevReadingCtrl = TextEditingController();
  final _currentReadingCtrl = TextEditingController();
  DateTime? _readingDate;
  final _unitsCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '8');
  DateTime? _dueDate;
  final _totalCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(); // for non-electricity
  // Water-specific controllers
  final _waterConnCtrl = TextEditingController();
  final _connectionTypeCtrl = TextEditingController();
  final _houseNumberCtrl = TextEditingController();
  final _waterProviderCtrl = TextEditingController();
  // Gas-specific controllers
  final _gasConsumerIdCtrl = TextEditingController();
  final _gasHouseNumberCtrl = TextEditingController();
  // WiFi-specific controllers
  final _wifiCustomerIdCtrl = TextEditingController();
  String _selectedWifiPlan = 'Basic';
  final _wifiHouseNumberCtrl = TextEditingController();
  final _wifiProviderCtrl = TextEditingController();
  // DTH-specific controllers
  final _dthSubscriberIdCtrl = TextEditingController();
  String _selectedDthPackage = '299 - 15 days';
  final _dthHouseNumberCtrl = TextEditingController();
  final _dthProviderCtrl = TextEditingController();
  // Others-specific controllers
  final _othersSpecifyCtrl = TextEditingController();
  final _othersHouseNumberCtrl = TextEditingController();
  final _othersProviderCtrl = TextEditingController();

  bool _loadingConsumers = true;
  String? _providerName; // e.g., 'kseb'
  List<_Consumer> _consumers = []; // filtered view
  List<_Consumer> _allConsumers = []; // full list from backend

  @override
  void initState() {
    super.initState();
    _initDefaults();
    _prevReadingCtrl.addListener(_recomputeUnitsAndTotal);
    _currentReadingCtrl.addListener(_recomputeUnitsAndTotal);
    _rateCtrl.addListener(_recomputeUnitsAndTotal);
    // Set default rate per unit based on utility type
    if (_isWater) {
      _rateCtrl.text = '10';
    } else if (_isElectricity) {
      _rateCtrl.text = '8';
    }
  }

  @override
  void dispose() {
    _billIdCtrl.dispose();
    _consumerNumberCtrl.dispose();
    _prevReadingCtrl.dispose();
    _currentReadingCtrl.dispose();
    _unitsCtrl.dispose();
    _rateCtrl.dispose();
    _totalCtrl.dispose();
    _amountCtrl.dispose();
    _waterConnCtrl.dispose();
    _connectionTypeCtrl.dispose();
    _houseNumberCtrl.dispose();
    _waterProviderCtrl.dispose();
    _gasConsumerIdCtrl.dispose();
    _gasHouseNumberCtrl.dispose();
    _wifiCustomerIdCtrl.dispose();
    _wifiHouseNumberCtrl.dispose();
    _wifiProviderCtrl.dispose();
    _dthSubscriberIdCtrl.dispose();
    _dthHouseNumberCtrl.dispose();
    _dthProviderCtrl.dispose();
    _othersSpecifyCtrl.dispose();
    _othersHouseNumberCtrl.dispose();
    _othersProviderCtrl.dispose();
    super.dispose();
  }

  Future<void> _initDefaults() async {
    // Generate bill id
    _billIdCtrl.text = _generateBillId();

    // Detect provider from saved username (kseb authority)
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username')?.toLowerCase() ?? '';
    if (username.endsWith('kseb')) {
      _providerName = 'kseb';
    } else {
      _providerName = 'kseb'; // default for now
    }
    await _fetchConsumers();
    if (mounted) setState(() => _loadingConsumers = false);
  }

  String _generateBillId() {
    final now = DateTime.now();
    // Timestamp for uniqueness: YYYYMMDDHHMMSS
    final ts =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    // Prefix by utility type
    final type = _utilityType.toLowerCase();
    String prefix;
    if (type == 'electricity') {
      prefix = 'KSEB';
    } else if (type == 'water') {
      prefix = 'KWA';
    } else if (type == 'gas') {
      prefix = 'LPG';
    } else if (type == 'wifi') {
      // Use provider name for WiFi if available; else WIFI
      prefix = (_providerName ?? 'WIFI').toUpperCase();
    } else if (type == 'dth') {
      // Always DTH for DTH utility type
      prefix = 'DTH';
    } else {
      // Others: no prefix, just timestamp
      return ts;
    }
    return '$prefix-$ts';
  }

  Future<void> _fetchConsumers() async {
    try {
      // Fetch all utilities (no provider filter) and filter by utility type client-side
      final uri = Uri.parse('${ApiConfig.baseUrl}/user-utility/list/');
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = (body['results'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final all = results
            .map(
              (e) => _Consumer(
                name: (e['user_name']?.toString() ?? '').trim(),
                number: (e['consumer_number']?.toString() ?? '').trim(),
                utilityType: (e['utility_type']?.toString() ?? '').trim(),
              ),
            )
            .where((c) => c.name.isNotEmpty || c.number.isNotEmpty)
            .toList();
        all.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        setState(() {
          _allConsumers = all;
          _applyConsumerFilter();
        });
      }
    } catch (_) {
      // ignore errors for now
    }
  }

  double? _amountFromPlan(String planLabel) {
    final match = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(planLabel.trim());
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  void _applyConsumerFilter() {
    final type = _utilityType.toLowerCase();
    final filtered = _allConsumers
        .where((c) => c.utilityType.toLowerCase() == type)
        .toList();
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    _consumers = filtered;
  }

  void _onSelectConsumer(String? name) {
    setState(() {
      _selectedConsumerName = name;
      final matched = _consumers.firstWhere(
        (c) => c.name == name,
        orElse: () =>
            _Consumer(name: name ?? '', number: '', utilityType: _utilityType),
      );
      _consumerNumberCtrl.text = matched.number;
      // Prefill previous reading from local history for this consumer
      _prefillPreviousReadingFromHistory();
    });
  }

  void _recomputeUnitsAndTotal() {
    final prev = double.tryParse(_prevReadingCtrl.text.trim());
    final curr = double.tryParse(_currentReadingCtrl.text.trim());
    final rate = double.tryParse(_rateCtrl.text.trim());

    if (prev == null || curr == null) {
      _unitsCtrl.text = '';
      if (_isElectricity || _isWater || _isGas) {
        _totalCtrl.text = '';
      }
      return;
    }
    final units = (curr - prev);
    _unitsCtrl.text = units >= 0 ? units.toStringAsFixed(2) : '0.00';

    if ((_isElectricity || _isWater || _isGas) && rate != null) {
      final total = (units >= 0 ? units : 0) * rate;
      _totalCtrl.text = total.toStringAsFixed(2);
    } else {
      if (_isElectricity || _isWater || _isGas) _totalCtrl.text = '';
    }
  }

  Future<void> _pickReadingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _readingDate = picked;
        _dueDate = picked.add(const Duration(days: 14));
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_readingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reading date')),
      );
      return;
    }
    // Ensure due date is computed from reading date (+14 days)
    _dueDate ??= _readingDate!.add(const Duration(days: 14));

    String fmtDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
            .trim();

    // Prepare payload for backend persistence
    final payload = {
      'bill_id': _billIdCtrl.text.trim(),
      'utility_type': _utilityType,
      'consumer_name': _selectedConsumerName,
      'consumer_number': _isElectricity
          ? _consumerNumberCtrl.text.trim()
          : null,
      'previous_reading': (_isElectricity || _isWater || _isGas)
          ? _prevReadingCtrl.text.trim()
          : null,
      'current_reading': (_isElectricity || _isWater || _isGas)
          ? _currentReadingCtrl.text.trim()
          : null,
      'reading_date': fmtDate(_readingDate!),
      'units_consumed': (_isElectricity || _isWater || _isGas)
          ? _unitsCtrl.text.trim()
          : null,
      'rate_per_unit': (_isElectricity || _isWater || _isGas)
          ? _rateCtrl.text.trim()
          : null,
      'due_date': fmtDate(_dueDate!),
      'total_amount':
          (_isElectricity || _isWater || _isGas || _isWifi || _isDth)
          ? _totalCtrl.text.trim()
          : _amountCtrl.text.trim(),
      'provider_name': _providerName,
      // Water extras
      'water_connection_number': _isWater ? _waterConnCtrl.text.trim() : null,
      // Gas extras
      'gas_consumer_id': _isGas ? _gasConsumerIdCtrl.text.trim() : null,
      // WiFi extras
      'wifi_consumer_id': _isWifi ? _wifiCustomerIdCtrl.text.trim() : null,
      'plan_name': _isWifi ? _selectedWifiPlan : null,
      // DTH extras
      'dth_subscriber_id': _isDth ? _dthSubscriberIdCtrl.text.trim() : null,
      'dth_package_name': _isDth ? _selectedDthPackage : null,
      // Others extras
      'specified_utility_type': _isOthers
          ? _othersSpecifyCtrl.text.trim()
          : null,
    };

    _saveToBackend(payload);
  }

  Future<void> _saveToBackend(Map<String, dynamic> payload) async {
    try {
      // Build minimal payload for utility_bill table
      final consumerId = _isElectricity
          ? _consumerNumberCtrl.text.trim()
          : _isWater
          ? _waterConnCtrl.text.trim()
          : _isGas
          ? _gasConsumerIdCtrl.text.trim()
          : _isWifi
          ? _wifiCustomerIdCtrl.text.trim()
          : _isDth
          ? _dthSubscriberIdCtrl.text.trim()
          : '';

      final minimal = {
        'utility_type': _utilityType,
        'bill_id': payload['bill_id'],
        'consumer_name': payload['consumer_name'],
        'consumer_id': consumerId.isNotEmpty ? consumerId : null,
        'previous_reading': (_isElectricity || _isWater || _isGas)
            ? payload['previous_reading']
            : null,
        'current_reading': (_isElectricity || _isWater || _isGas)
            ? payload['current_reading']
            : null,
        'total_amount':
            (_isElectricity || _isWater || _isGas || _isWifi || _isDth)
            ? payload['total_amount']
            : payload['total_amount'],
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/utility-bill/add/');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(minimal),
      );
      if (!mounted) return;
      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bill saved: ${payload['bill_id']} (₹${payload['total_amount']})',
            ),
          ),
        );
        // Save last current reading for this consumer for next time (electricity only)
        if (_isElectricity) {
          await _saveLastReadingForConsumer();
        }
        _resetForm();
      } else {
        final msg = resp.body.isNotEmpty ? resp.body : 'Failed to save bill';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _prefillPreviousReadingFromHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final mapStr = prefs.getString('last_reading_per_consumer') ?? '{}';
    Map<String, dynamic> data;
    try {
      data = jsonDecode(mapStr) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    final key = _consumerNumberCtrl.text.trim().isNotEmpty
        ? _consumerNumberCtrl.text.trim()
        : (_selectedConsumerName ?? '').trim();
    final last = data[key]?.toString();
    if (last != null && last.isNotEmpty) {
      setState(() {
        _prevReadingCtrl.text = last;
        _recomputeUnitsAndTotal();
      });
    }
  }

  Future<void> _saveLastReadingForConsumer() async {
    final key = _consumerNumberCtrl.text.trim().isNotEmpty
        ? _consumerNumberCtrl.text.trim()
        : (_selectedConsumerName ?? '').trim();
    if (key.isEmpty) return;
    final current = _currentReadingCtrl.text.trim();
    if (current.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final mapStr = prefs.getString('last_reading_per_consumer') ?? '{}';
    Map<String, dynamic> data;
    try {
      data = jsonDecode(mapStr) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    data[key] = current;
    await prefs.setString('last_reading_per_consumer', jsonEncode(data));
  }

  void _resetForm() {
    setState(() {
      _billIdCtrl.text = _generateBillId();
      _selectedConsumerName = null;
      _consumerNumberCtrl.clear();
      _prevReadingCtrl.clear();
      _currentReadingCtrl.clear();
      _readingDate = null;
      _unitsCtrl.clear();
      _rateCtrl.text = _isWater
          ? '10'
          : (_isElectricity || _isGas)
          ? '8'
          : '';
      _dueDate = null;
      if (_isWifi) {
        _totalCtrl.text = '799.00';
      } else if (_isDth) {
        final amt = _amountFromPlan(_selectedDthPackage) ?? 0.0;
        _totalCtrl.text = amt.toStringAsFixed(2);
      } else {
        _totalCtrl.clear();
      }
      _amountCtrl.clear();
      _waterConnCtrl.clear();
      _connectionTypeCtrl.clear();
      _houseNumberCtrl.clear();
      _waterProviderCtrl.clear();
      _gasConsumerIdCtrl.clear();
      _gasHouseNumberCtrl.clear();
      _wifiCustomerIdCtrl.clear();
      _selectedWifiPlan = 'Basic';
      _wifiHouseNumberCtrl.clear();
      _wifiProviderCtrl.clear();
      _dthSubscriberIdCtrl.clear();
      _selectedDthPackage = '299 - 15 days';
      _dthHouseNumberCtrl.clear();
      _dthProviderCtrl.clear();
      _othersSpecifyCtrl.clear();
      _othersHouseNumberCtrl.clear();
      _othersProviderCtrl.clear();
    });
  }

  bool get _isElectricity => _utilityType.toLowerCase() == 'electricity';
  bool get _isWater => _utilityType.toLowerCase() == 'water';
  bool get _isGas => _utilityType.toLowerCase() == 'gas';
  bool get _isWifi => _utilityType.toLowerCase() == 'wifi';
  bool get _isDth => _utilityType.toLowerCase() == 'dth';
  bool get _isOthers => _utilityType.toLowerCase() == 'others';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CurvedHeaderPage(
        title: 'Generate Bill',
        headerHeight: 180,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        titleAlignment: HeaderTitleAlignment.left,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Utility Type
              DropdownButtonFormField<String>(
                initialValue: _utilityType,
                items:
                    const [
                          'Electricity',
                          'Water',
                          'Gas',
                          'WiFi',
                          'DTH',
                          'Others',
                        ]
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _utilityType = v;
                    // Clear electricity-specific computed fields when switching away
                    if (!_isElectricity) {
                      _consumerNumberCtrl.clear();
                      _prevReadingCtrl.clear();
                      _currentReadingCtrl.clear();
                      _unitsCtrl.clear();
                      _totalCtrl.clear();
                    }
                    // Reset consumer selection and apply filter by utility type
                    _selectedConsumerName = null;
                    _applyConsumerFilter();
                    // Update default rate per unit when changing type
                    if (_isWater) {
                      _rateCtrl.text = '10';
                    } else if (_isElectricity) {
                      _rateCtrl.text = '8';
                    } else if (_isGas) {
                      _rateCtrl.text = '8';
                    } else {
                      _rateCtrl.text = '';
                    }
                    // Regenerate Bill ID to reflect new utility type prefix
                    _billIdCtrl.text = _generateBillId();
                    // Set totals for WiFi/DTH
                    if (_isWifi) {
                      _selectedWifiPlan = 'Basic';
                      _totalCtrl.text = '799.00';
                    } else if (_isDth) {
                      _selectedDthPackage = '299 - 15 days';
                      final amt = _amountFromPlan(_selectedDthPackage) ?? 0.0;
                      _totalCtrl.text = amt.toStringAsFixed(2);
                    }
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Utility Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 12),
              // Bill ID
              TextFormField(
                controller: _billIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bill ID',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Consumer Name dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedConsumerName,
                items: _consumers
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c.name,
                        child: Text(c.name.isNotEmpty ? c.name : 'Unknown'),
                      ),
                    )
                    .toList(),
                onChanged: _loadingConsumers ? null : _onSelectConsumer,
                decoration: const InputDecoration(
                  labelText: 'Consumer Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select a consumer' : null,
              ),
              const SizedBox(height: 12),

              // Consumer number (auto)
              if (_isElectricity) ...[
                TextFormField(
                  controller: _consumerNumberCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Consumer Number',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (v) =>
                      _isElectricity && (v == null || v.trim().isEmpty)
                      ? 'Missing consumer number'
                      : null,
                ),
                const SizedBox(height: 12),
              ],

              // Water-specific fields (revised)
              if (_isWater) ...[
                TextFormField(
                  controller: _waterConnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Water Connection Number',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (v) => _isWater && (v == null || v.trim().isEmpty)
                      ? 'Enter water connection number'
                      : null,
                ),
                const SizedBox(height: 12),
              ],

              // WiFi-specific fields
              if (_isWifi) ...[
                TextFormField(
                  controller: _wifiCustomerIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer ID / Account Number',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (v) => _isWifi && (v == null || v.trim().isEmpty)
                      ? 'Enter customer/account number'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: 'Basic',
                  items: const ['Basic']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: null,
                  decoration: const InputDecoration(
                    labelText: 'Selected Plan',
                    prefixIcon: Icon(Icons.wifi),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Gas-specific fields
              if (_isGas) ...[
                TextFormField(
                  controller: _gasConsumerIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gas Consumer ID',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (v) => _isGas && (v == null || v.trim().isEmpty)
                      ? 'Enter gas consumer ID'
                      : null,
                ),
                const SizedBox(height: 12),
              ],

              // DTH-specific fields
              if (_isDth) ...[
                TextFormField(
                  controller: _dthSubscriberIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subscriber ID',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (v) => _isDth && (v == null || v.trim().isEmpty)
                      ? 'Enter subscriber ID'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDthPackage,
                  items:
                      const ['299 - 15 days', '499 - 30 days', '799 - 60 days']
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() {
                    _selectedDthPackage = v ?? '299 - 15 days';
                    final amt = _amountFromPlan(_selectedDthPackage) ?? 0.0;
                    _totalCtrl.text = amt.toStringAsFixed(2);
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Package Name',
                    prefixIcon: Icon(Icons.tv_outlined),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Others-specific fields
              if (_isOthers) ...[
                TextFormField(
                  controller: _othersSpecifyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Specify Utility Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (v) => _isOthers && (v == null || v.trim().isEmpty)
                      ? 'Specify the utility type'
                      : null,
                ),
                const SizedBox(height: 12),
              ],

              // Previous reading
              if (_isElectricity || _isWater || _isGas) ...[
                TextFormField(
                  controller: _prevReadingCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Previous Reading',
                    prefixIcon: Icon(Icons.speed),
                  ),
                  validator: (v) =>
                      (_isElectricity || _isWater || _isGas) &&
                          (double.tryParse(v?.trim() ?? '') == null)
                      ? 'Enter a valid number'
                      : null,
                ),
                const SizedBox(height: 12),
              ],

              // Current meter reading
              if (_isElectricity || _isWater || _isGas) ...[
                TextFormField(
                  controller: _currentReadingCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Current Meter Reading',
                    prefixIcon: Icon(Icons.speed_outlined),
                  ),
                  validator: (v) =>
                      (_isElectricity || _isWater || _isGas) &&
                          (double.tryParse(v?.trim() ?? '') == null)
                      ? 'Enter a valid number'
                      : null,
                ),
                const SizedBox(height: 12),
              ],

              // Reading date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _readingDate == null
                          ? 'No reading date selected'
                          : 'Reading: ${_readingDate!.day}/${_readingDate!.month}/${_readingDate!.year}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickReadingDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick Reading Date'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Units consumed / Water used (auto)
              if (_isElectricity || _isWater || _isGas) ...[
                TextFormField(
                  controller: _unitsCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: _isWater
                        ? 'Water Used'
                        : _isGas
                        ? 'Gas Used'
                        : 'Units Consumed',
                    prefixIcon: const Icon(Icons.bolt_outlined),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Rate per unit
              if (_isElectricity || _isWater || _isGas) ...[
                TextFormField(
                  controller: _rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Rate per Unit (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (v) =>
                      (_isElectricity || _isWater || _isGas) &&
                          (double.tryParse(v?.trim() ?? '') == null)
                      ? 'Enter a valid rate'
                      : null,
                ),
                const SizedBox(height: 12),
              ],

              // Due date
              Row(
                children: [
                  const Icon(Icons.event, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'Due date will be set to Reading Date + 14 days'
                          : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} (auto)',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total amount (auto for electricity/water/gas/wifi/dth)
              if (_isElectricity || _isWater || _isGas || _isWifi || _isDth)
                TextFormField(
                  controller: _totalCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount (₹)',
                    prefixIcon: Icon(Icons.summarize_outlined),
                  ),
                )
              else
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (v) =>
                      !_isElectricity &&
                          (double.tryParse(v?.trim() ?? '') == null)
                      ? 'Enter a valid amount'
                      : null,
                ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('Generate Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34B3A0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Consumer {
  final String name;
  final String number;
  final String utilityType;
  _Consumer({
    required this.name,
    required this.number,
    required this.utilityType,
  });
}
