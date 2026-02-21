import 'package:flutter/material.dart';
import '../../widgets/theme_header.dart';
import '../../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddBillPage extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final int? recordId;
  const AddBillPage({super.key, this.initial, this.recordId});

  @override
  State<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _customUtilityCtrl = TextEditingController();
  final _houseNumberCtrl = TextEditingController();
  final _providerNameCtrl = TextEditingController();
  final _consumerNumberCtrl = TextEditingController();
  final _waterConnectNumberCtrl = TextEditingController();
  final _gasConsumerIdCtrl = TextEditingController();
  final _wifiCustomerIdCtrl = TextEditingController();
  final _dthSubscriberIdCtrl = TextEditingController();
  final _dthPackageNameCtrl = TextEditingController();
  String? _selectedUtility;
  String? _connectionType;
  String? _wifiSelectedPlan;
  String _userName = '';
  int? _editingId;
  static const List<String> _utilityOptions = [
    'Electricity',
    'Water',
    'Gas',
    'WiFi',
    'DTH',
    'Others',
  ];
  static const List<String> _connectionTypeOptions = ['Domestic', 'Commercial'];
  static const List<String> _wifiPlanOptions = [
    '50 Mbps',
    '100 Mbps',
    '200 Mbps',
    '300 Mbps',
  ];

  @override
  void dispose() {
    _customUtilityCtrl.dispose();
    _houseNumberCtrl.dispose();
    _providerNameCtrl.dispose();
    _consumerNumberCtrl.dispose();
    _waterConnectNumberCtrl.dispose();
    _gasConsumerIdCtrl.dispose();
    _wifiCustomerIdCtrl.dispose();
    _dthSubscriberIdCtrl.dispose();
    _dthPackageNameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadHouseNumberFromProfile();
    _prefillIfEditing();
  }

  Future<void> _loadHouseNumberFromProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        return;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/profiles/');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle both list and single object responses
        Map<String, dynamic>? profile;
        
        if (data is List && data.isNotEmpty) {
          profile = data[0] as Map<String, dynamic>;
        } else if (data is Map) {
          profile = data as Map<String, dynamic>;
        }

        if (profile != null) {
          final houseNumber = profile['house_number'] as String?;
          if (houseNumber != null && 
              houseNumber.isNotEmpty && 
              mounted && 
              _houseNumberCtrl.text.isEmpty) {
            setState(() {
              _houseNumberCtrl.text = houseNumber;
            });
          }
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _prefillIfEditing() {
    final init = widget.initial;
    if (init == null && widget.recordId == null) return;
    _editingId = widget.recordId ?? (init?['id'] as int?);
    final utilityType = init?['utility_type'] as String?;
    setState(() {
      _selectedUtility = utilityType;
      _providerNameCtrl.text = (init?['provider_name'] as String?) ?? '';
      _houseNumberCtrl.text = (init?['meter_number'] as String?) ?? '';
      _connectionType =
          (init?['connection_type'] as String?) ?? _connectionType;
      _wifiSelectedPlan = (init?['plan_name'] as String?) ?? _wifiSelectedPlan;
    });
    // Fill conditional fields
    _consumerNumberCtrl.text =
        (init?['consumer_number'] as String?) ?? _consumerNumberCtrl.text;
    _waterConnectNumberCtrl.text =
        (init?['water_connection_number'] as String?) ??
        _waterConnectNumberCtrl.text;
    _gasConsumerIdCtrl.text =
        (init?['gas_connection_number'] as String?) ?? _gasConsumerIdCtrl.text;
    _wifiCustomerIdCtrl.text =
        (init?['wifi_consumer_id'] as String?) ?? _wifiCustomerIdCtrl.text;
    _dthSubscriberIdCtrl.text =
        (init?['dth_subscriber_id'] as String?) ?? _dthSubscriberIdCtrl.text;
    _dthPackageNameCtrl.text =
        (init?['plan_name'] as String?) ?? _dthPackageNameCtrl.text;
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name =
        prefs.getString('user_username') ??
        prefs.getString('full_name') ??
        'User';
    if (!mounted) return;
    setState(() => _userName = name);
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUtility == 'Electricity') {
      if (_consumerNumberCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the consumer number')),
        );
        return;
      }
      if (_connectionType == null || _connectionType!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the connection type')),
        );
        return;
      }
    }
    if (_selectedUtility == 'Water') {
      if (_waterConnectNumberCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the water connection number'),
          ),
        );
        return;
      }
      if (_connectionType == null || _connectionType!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the connection type')),
        );
        return;
      }
    }
    if (_selectedUtility == 'Gas') {
      if (_gasConsumerIdCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the gas consumer ID')),
        );
        return;
      }
    }
    if (_selectedUtility == 'WiFi') {
      if (_wifiCustomerIdCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the customer/account number'),
          ),
        );
        return;
      }
      if (_wifiSelectedPlan == null || _wifiSelectedPlan!.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a plan')));
        return;
      }
    }
    if (_selectedUtility == 'DTH') {
      if (_dthSubscriberIdCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the subscriber ID')),
        );
        return;
      }
      if (_dthPackageNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the package name')),
        );
        return;
      }
    }

    final utilityValue = _selectedUtility == 'Others'
        ? _customUtilityCtrl.text.trim()
        : (_selectedUtility ?? '');

    final Map<String, dynamic> payload = {
      'utility_type': utilityValue,
      'provider_name': _providerNameCtrl.text.trim(),
      // Map house number into both meter_number (for backward compat) and house_number
      'meter_number': _houseNumberCtrl.text.trim(),
      'house_number': _houseNumberCtrl.text.trim(),
      'user_name': _userName,
    };
    if (_selectedUtility == 'Electricity') {
      payload['consumer_number'] = _consumerNumberCtrl.text.trim();
      if (_connectionType != null) payload['connection_type'] = _connectionType;
    }
    if (_selectedUtility == 'Water') {
      payload['water_connection_number'] = _waterConnectNumberCtrl.text.trim();
      if (_connectionType != null) payload['connection_type'] = _connectionType;
    }
    if (_selectedUtility == 'Gas') {
      payload['gas_connection_number'] = _gasConsumerIdCtrl.text.trim();
    }
    if (_selectedUtility == 'WiFi') {
      payload['wifi_consumer_id'] = _wifiCustomerIdCtrl.text.trim();
      if (_wifiSelectedPlan != null) payload['plan_name'] = _wifiSelectedPlan;
    }
    if (_selectedUtility == 'DTH') {
      payload['dth_subscriber_id'] = _dthSubscriberIdCtrl.text.trim();
      payload['plan_name'] = _dthPackageNameCtrl.text.trim();
    }

    // Post to backend
    _submitToBackend(payload);
  }

  Future<void> _submitToBackend(Map<String, dynamic> payload) async {
    try {
      final isEditing = _editingId != null;
      final uri = isEditing
          ? Uri.parse('${ApiConfig.baseUrl}/user-utility/${_editingId!}/')
          : Uri.parse('${ApiConfig.baseUrl}/user-utility/add/');
      final resp = await (isEditing
          ? http.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
          : http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ));
      final ok = isEditing
          ? (resp.statusCode == 200)
          : (resp.statusCode == 201);
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Successfully updated' : 'Successfully added',
            ),
          ),
        );
        Navigator.pop(context, {'id': _editingId, ...payload});
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget pill(Widget child) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    InputDecoration pillDecoration(String hint, IconData icon) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: InputBorder.none,
      );
    }

    return Scaffold(
      body: CurvedHeaderPage(
        title: 'Add Bill',
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
              pill(
                DropdownButtonFormField<String>(
                  initialValue: _utilityOptions.contains(_selectedUtility)
                      ? _selectedUtility
                      : null,
                  decoration: pillDecoration(
                    'Utility Type',
                    Icons.category_outlined,
                  ),
                  items: _utilityOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedUtility = v;
                    _connectionType = null;
                    _wifiSelectedPlan = null;
                  }),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please select a utility type'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedUtility == 'Others')
                pill(
                  TextFormField(
                    controller: _customUtilityCtrl,
                    decoration: pillDecoration(
                      'Specify Utility Type',
                      Icons.edit_outlined,
                    ),
                    validator: (v) {
                      if (_selectedUtility == 'Others' &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Please specify the utility type';
                      }
                      return null;
                    },
                  ),
                ),
              if (_selectedUtility == 'Others') const SizedBox(height: 12),
              if (_selectedUtility == 'Electricity')
                pill(
                  TextFormField(
                    controller: _consumerNumberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: pillDecoration(
                      'Consumer Number',
                      Icons.numbers,
                    ),
                  ),
                ),
              if (_selectedUtility == 'Electricity') const SizedBox(height: 12),
              if (_selectedUtility == 'Electricity')
                pill(
                  DropdownButtonFormField<String>(
                    initialValue: _connectionTypeOptions.contains(_connectionType)
                        ? _connectionType
                        : null,
                    decoration: pillDecoration(
                      'Connection Type',
                      Icons.power_outlined,
                    ),
                    items: _connectionTypeOptions
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _connectionType = v),
                  ),
                ),
              if (_selectedUtility == 'Electricity') const SizedBox(height: 12),
              if (_selectedUtility == 'Water')
                pill(
                  TextFormField(
                    controller: _waterConnectNumberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: pillDecoration(
                      'Water Connection Number',
                      Icons.water_drop_outlined,
                    ),
                  ),
                ),
              if (_selectedUtility == 'Water') const SizedBox(height: 12),
              if (_selectedUtility == 'Water')
                pill(
                  DropdownButtonFormField<String>(
                    initialValue: _connectionTypeOptions.contains(_connectionType)
                        ? _connectionType
                        : null,
                    decoration: pillDecoration(
                      'Connection Type',
                      Icons.power_outlined,
                    ),
                    items: _connectionTypeOptions
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _connectionType = v),
                  ),
                ),
              if (_selectedUtility == 'Water') const SizedBox(height: 12),
              if (_selectedUtility == 'Gas')
                pill(
                  TextFormField(
                    controller: _gasConsumerIdCtrl,
                    decoration: pillDecoration(
                      'Gas Consumer ID',
                      Icons.local_gas_station_outlined,
                    ),
                  ),
                ),
              if (_selectedUtility == 'Gas') const SizedBox(height: 12),
              if (_selectedUtility == 'WiFi')
                pill(
                  TextFormField(
                    controller: _wifiCustomerIdCtrl,
                    decoration: pillDecoration(
                      'Customer ID / Account Number',
                      Icons.perm_identity,
                    ),
                  ),
                ),
              if (_selectedUtility == 'WiFi') const SizedBox(height: 12),
              if (_selectedUtility == 'WiFi')
                pill(
                  DropdownButtonFormField<String>(
                    initialValue: _wifiPlanOptions.contains(_wifiSelectedPlan)
                        ? _wifiSelectedPlan
                        : null,
                    decoration: pillDecoration('Selected Plan', Icons.wifi),
                    items: _wifiPlanOptions
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _wifiSelectedPlan = v),
                  ),
                ),
              if (_selectedUtility == 'WiFi') const SizedBox(height: 12),
              if (_selectedUtility == 'DTH')
                pill(
                  TextFormField(
                    controller: _dthSubscriberIdCtrl,
                    decoration: pillDecoration(
                      'Subscriber ID',
                      Icons.subscriptions_outlined,
                    ),
                  ),
                ),
              if (_selectedUtility == 'DTH') const SizedBox(height: 12),
              if (_selectedUtility == 'DTH')
                pill(
                  TextFormField(
                    controller: _dthPackageNameCtrl,
                    decoration: pillDecoration(
                      'Package Name',
                      Icons.tv_outlined,
                    ),
                  ),
                ),
              if (_selectedUtility == 'DTH') const SizedBox(height: 12),
              pill(
                TextFormField(
                  controller: _houseNumberCtrl,
                  decoration: pillDecoration(
                    'House Number',
                    Icons.home_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              pill(
                TextFormField(
                  controller: _providerNameCtrl,
                  decoration: pillDecoration(
                    'Provider Name',
                    Icons.business_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                      // Use global ElevatedButton theme colors
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
