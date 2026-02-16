import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/customer_model.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isPermissionGranted = false;
  String _currentFilter = 'All'; // 'All', 'Pending'
  
  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedCustomerIds = {};

  // SMS Settings State
  bool _isAutoSmsEnabled = false;
  String _smsTemplate = "नमस्कार {name}, चिकन मार्ट मध्ये आपले स्वागत आहे! आपली सध्याची थकबाकी ₹{balance} आहे.";
  int _smsIntervalDays = 7;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _loadSmsSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      Provider.of<DatabaseService>(context, listen: false).fetchCustomers(auth);
    });
  }

  Future<void> _loadSmsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoSmsEnabled = prefs.getBool('auto_sms_enabled') ?? false;
      _smsTemplate = prefs.getString('sms_template') ?? _smsTemplate;
      _smsIntervalDays = prefs.getInt('sms_interval_days') ?? 7;
    });
  }

  Future<void> _saveSmsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sms_enabled', _isAutoSmsEnabled);
    await prefs.setString('sms_template', _smsTemplate);
    await prefs.setInt('sms_interval_days', _smsIntervalDays);
  }

  Future<void> _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.contacts,
    ].request();

    setState(() {
      _isPermissionGranted = statuses[Permission.contacts]!.isGranted;
    });

    if (_isPermissionGranted) {
      _fetchDeviceContacts();
    }
  }

  Future<void> _fetchDeviceContacts() async {
    try {
      await FlutterContacts.getContacts(withProperties: true);
      // _contacts usage removed as per lint, but function kept for future expansion
    } catch (e) {
      debugPrint("Error fetching contacts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isSelectionMode = false; _selectedCustomerIds.clear(); }))
          : null,
        title: _isSelectionMode 
          ? Text('${_selectedCustomerIds.length} Selected')
          : Text('Customer Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 0,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _selectedCustomerIds.isEmpty ? null : () => _sendBulkSMS(db),
            )
          else ...[
            _buildFilterMenu(),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showCustomerDialog(context, auth, db),
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: db.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildFullCustomerList(db, auth),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final templateController = TextEditingController(text: _smsTemplate);
    final intervalController = TextEditingController(text: _smsIntervalDays.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('SMS Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Auto SMS Reminder'),
                  subtitle: const Text('Enable automatic payment reminders'),
                  value: _isAutoSmsEnabled,
                  onChanged: (val) {
                    setDialogState(() => _isAutoSmsEnabled = val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: templateController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'SMS Template',
                    helperText: 'Use {name} and {balance} as placeholders',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: intervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Interval (Days)',
                    helperText: 'How many days before/after due date',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _smsTemplate = templateController.text;
                  _smsIntervalDays = int.tryParse(intervalController.text) ?? 7;
                });
                _saveSmsSettings();
                Navigator.pop(context);
              },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendBulkSMS(DatabaseService db) async {
    final selectedCustomers = db.customers.where((c) => _selectedCustomerIds.contains(c.id)).toList();
    if (selectedCustomers.isEmpty) return;

    for (var customer in selectedCustomers) {
      String message = _smsTemplate
          .replaceAll('{name}', customer.name)
          .replaceAll('{balance}', customer.advanceBalance.toStringAsFixed(0));
      
      final Uri smsUri = Uri.parse('sms:${customer.phone}?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
      await Future.delayed(const Duration(milliseconds: 600));
    }
    
    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedCustomerIds.clear();
      });
    }
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) => setState(() => _currentFilter = value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'All', child: Text('All Customers')),
        const PopupMenuItem(value: 'Pending', child: Text('Pending Payments')),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('All'),
          _filterChip('Pending'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _currentFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _currentFilter = label);
        },
        selectedColor: const Color(0xFF3F51B5),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF3F51B5),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search Name or Number...',
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear, color: Colors.white), onPressed: () { _searchController.clear(); setState(() {}); })
            : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFullCustomerList(DatabaseService db, AuthService auth) {
    final query = _searchController.text.toLowerCase();
    
    List<CustomerModel> dbCustomers = db.customers.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(query) || c.phone.contains(query);
      if (!matchesSearch) return false;

      if (_currentFilter == 'Pending') return c.advanceBalance > 0;
      return true;
    }).toList();

    dbCustomers.sort((a, b) {
      if (a.advanceBalance > 0 && b.advanceBalance <= 0) return -1;
      if (a.advanceBalance <= 0 && b.advanceBalance > 0) return 1;

      if (a.nextPaymentDate != null && b.nextPaymentDate != null) {
        return a.nextPaymentDate!.compareTo(b.nextPaymentDate!);
      }
      if (a.nextPaymentDate != null && b.nextPaymentDate == null) return -1;
      if (a.nextPaymentDate == null && b.nextPaymentDate != null) return 1;

      return 0;
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dbCustomers.length,
      itemBuilder: (context, index) {
        final customer = dbCustomers[index];
        bool isUrgent = customer.advanceBalance > 0 && customer.nextPaymentDate != null;
        return _buildCustomerCard(customer, auth, db, isUrgent: isUrgent);
      },
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, AuthService auth, DatabaseService db, {bool isUrgent = false}) {
    bool hasBalance = customer.advanceBalance > 0;
    bool isSelected = _selectedCustomerIds.contains(customer.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUrgent ? 4 : 2,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
          ? const BorderSide(color: Color(0xFF3F51B5), width: 2) 
          : (isUrgent ? BorderSide(color: Colors.orange.shade300, width: 1) : BorderSide.none),
      ),
      child: InkWell(
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedCustomerIds.add(customer.id);
          });
        },
        onTap: _isSelectionMode ? () {
          setState(() {
            if (isSelected) {
              _selectedCustomerIds.remove(customer.id);
              if (_selectedCustomerIds.isEmpty) _isSelectionMode = false;
            } else {
              _selectedCustomerIds.add(customer.id);
            }
          });
        } : null,
        child: ExpansionTile(
          enabled: !_isSelectionMode,
          leading: _isSelectionMode 
            ? Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedCustomerIds.add(customer.id);
                    } else {
                      _selectedCustomerIds.remove(customer.id);
                      if (_selectedCustomerIds.isEmpty) _isSelectionMode = false;
                    }
                  });
                },
              )
            : CircleAvatar(
                backgroundColor: hasBalance ? Colors.red.shade50 : Colors.green.shade50,
                child: Text(customer.name[0].toUpperCase(), 
                  style: TextStyle(color: hasBalance ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
              ),
          title: Row(
            children: [
              Expanded(child: Text(customer.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16))),
              if (!_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _showDeleteConfirm(customer.id, auth, db),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(customer.phone, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('₹${customer.advanceBalance.toStringAsFixed(0)}', 
                style: TextStyle(
                  color: hasBalance ? Colors.red : Colors.green, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 18
                )),
              if (customer.nextPaymentDate != null && hasBalance)
                Text(
                  'Due: ${DateFormat('dd/MM/yy').format(customer.nextPaymentDate!)}',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionButton(Icons.call, 'Call', Colors.green, () => launchUrl(Uri.parse('tel:${customer.phone}'))),
                      _actionButton(Icons.message, 'SMS', Colors.deepOrange, () => _sendSMS(customer)),
                      _actionButton(Icons.edit, 'Edit', Colors.blue, () => _showCustomerDialog(context, auth, db, customer: customer)),
                      _actionButton(Icons.payments, 'Pay', Colors.orange, () => _showPaymentDialog(customer, auth, db)),
                    ],
                  ),
                  if (hasBalance) ...[
                    const Divider(),
                    TextButton.icon(
                      onPressed: () => _updatePaymentDate(customer, auth, db),
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('Update Next Payment Date', style: TextStyle(fontSize: 12)),
                    )
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(String id, AuthService auth, DatabaseService db) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: const Text('Are you sure you want to remove this customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              bool success = await db.deleteCustomer(id, auth);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePaymentDate(CustomerModel customer, AuthService auth, DatabaseService db) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: customer.nextPaymentDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final updatedCust = CustomerModel(
        id: customer.id, name: customer.name, phone: customer.phone,
        email: customer.email, address: customer.address, advanceBalance: customer.advanceBalance,
        nextPaymentDate: picked, createdAt: customer.createdAt,
      );
      await db.updateCustomer(updatedCust, auth);
    }
  }

  void _sendSMS(CustomerModel customer) async {
    String message = _smsTemplate
        .replaceAll('{name}', customer.name)
        .replaceAll('{balance}', customer.advanceBalance.toStringAsFixed(0));
    launchUrl(Uri.parse('sms:${customer.phone}?body=${Uri.encodeComponent(message)}'));
  }

  void _showCustomerDialog(BuildContext context, AuthService auth, DatabaseService db, {CustomerModel? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final phoneController = TextEditingController(text: customer?.phone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newCustomer = CustomerModel(
                  id: customer?.id ?? '', name: nameController.text, phone: phoneController.text,
                  createdAt: customer?.createdAt ?? DateTime.now(), advanceBalance: customer?.advanceBalance ?? 0.0,
                  nextPaymentDate: customer?.nextPaymentDate,
                );
                bool success;
                if (customer == null) {
                  success = await db.addCustomer(newCustomer, auth);
                } else {
                  success = await db.updateCustomer(newCustomer, auth);
                }
                if (success && mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(CustomerModel customer, AuthService auth, DatabaseService db) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ₹${customer.advanceBalance}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Paid')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final updatedCust = CustomerModel(
                  id: customer.id, name: customer.name, phone: customer.phone,
                  advanceBalance: customer.advanceBalance - double.parse(controller.text),
                  nextPaymentDate: customer.nextPaymentDate, createdAt: customer.createdAt,
                );
                bool success = await db.updateCustomer(updatedCust, auth);
                if (success && mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
