import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/customer_model.dart';

class CustomerScreen extends StatefulWidget {
  @override
  _CustomerScreenState createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      Provider.of<DatabaseService>(context, listen: false).fetchCustomers(auth);
    });
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
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _contacts = contacts;
      });
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
        title: Text('Customer Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF3F51B5),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => _showCustomerDialog(context, auth, db),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: db.isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildFullCustomerList(db, auth),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF3F51B5),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search Name or Number...',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(icon: Icon(Icons.clear, color: Colors.white), onPressed: () { _searchController.clear(); setState(() {}); })
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
    
    // Filter database customers
    List<CustomerModel> dbCustomers = db.customers.where((c) => 
      c.name.toLowerCase().contains(query) || c.phone.contains(query)
    ).toList();

    // Separate customers who have an upcoming payment date (Remaining Balance)
    List<CustomerModel> urgentCustomers = dbCustomers.where((c) => 
      c.advanceBalance > 0 && c.nextPaymentDate != null
    ).toList();

    // Sort urgent customers by date (closest date first)
    urgentCustomers.sort((a, b) => a.nextPaymentDate!.compareTo(b.nextPaymentDate!));

    // Remaining customers
    List<CustomerModel> otherCustomers = dbCustomers.where((c) => 
      !urgentCustomers.contains(c)
    ).toList();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (urgentCustomers.isNotEmpty) ...[
          _buildSectionHeader('Pending Payments (Upcoming)', Colors.orange.shade900),
          ...urgentCustomers.map((c) => _buildCustomerCard(c, auth, db, isUrgent: true)),
          SizedBox(height: 16),
        ],
        
        if (otherCustomers.isNotEmpty) ...[
          _buildSectionHeader('All Customers', Color(0xFF3F51B5)),
          ...otherCustomers.map((c) => _buildCustomerCard(c, auth, db)),
        ],

        // Show phone contacts if searching
        if (_searchController.text.isNotEmpty) ...[
          _buildSearchResults(db, auth),
        ],
      ],
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, AuthService auth, DatabaseService db, {bool isUrgent = false}) {
    bool hasBalance = customer.advanceBalance > 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isUrgent ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUrgent ? BorderSide(color: Colors.orange.shade300, width: 1) : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: hasBalance ? Colors.red.shade50 : Colors.green.shade50,
          child: Text(customer.name[0].toUpperCase(), 
            style: TextStyle(color: hasBalance ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
        ),
        title: Text(customer.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Row(
          children: [
            Icon(Icons.phone, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text(customer.phone, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                  Divider(),
                  TextButton.icon(
                    onPressed: () => _updatePaymentDate(customer, auth, db),
                    icon: Icon(Icons.calendar_month, size: 16),
                    label: Text('Update Next Payment Date', style: TextStyle(fontSize: 12)),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Support Methods ---
  Future<void> _updatePaymentDate(CustomerModel customer, AuthService auth, DatabaseService db) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: customer.nextPaymentDate ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
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
    final String message = "नमस्कार ${customer.name}, चिकन मार्ट मध्ये आपले स्वागत आहे! आपली सध्याची थकबाकी ₹${customer.advanceBalance.toStringAsFixed(0)} आहे.";
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
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newCustomer = CustomerModel(
                  id: customer?.id ?? '', name: nameController.text, phone: phoneController.text,
                  createdAt: customer?.createdAt ?? DateTime.now(), advanceBalance: customer?.advanceBalance ?? 0.0,
                  nextPaymentDate: customer?.nextPaymentDate,
                );
                if (customer == null) await db.addCustomer(newCustomer, auth);
                else await db.updateCustomer(newCustomer, auth);
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
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
        title: Text('Receive Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ₹${customer.advanceBalance}', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount Paid')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final updatedCust = CustomerModel(
                  id: customer.id, name: customer.name, phone: customer.phone,
                  advanceBalance: customer.advanceBalance - double.parse(controller.text),
                  nextPaymentDate: customer.nextPaymentDate, createdAt: customer.createdAt,
                );
                await db.updateCustomer(updatedCust, auth);
                Navigator.pop(context);
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(DatabaseService db, AuthService auth) {
    final query = _searchController.text.toLowerCase();
    final contactMatches = _contacts.where((c) => c.displayName.toLowerCase().contains(query) || (c.phones.isNotEmpty && c.phones.first.number.contains(query))).toList();
    if (contactMatches.isEmpty) return SizedBox.shrink();
    return Column(
      children: [
        _buildSectionHeader('Phone Contacts', Colors.grey),
        ...contactMatches.map((c) => _buildContactItem(c, auth, db)),
      ],
    );
  }

  Widget _buildContactItem(Contact contact, AuthService auth, DatabaseService db) {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.person_add)),
      title: Text(contact.displayName),
      onTap: () async {
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number.replaceAll(RegExp(r'\D'), '') : '';
        await db.addCustomer(CustomerModel(id: '', name: contact.displayName, phone: phone, createdAt: DateTime.now()), auth);
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
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
