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
                : _searchController.text.isEmpty
                    ? _buildCustomerList(db, auth)
                    : _buildSearchResults(db, auth),
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
          hintText: 'Search Database or Contacts...',
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

  Widget _buildCustomerList(DatabaseService db, AuthService auth) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: db.customers.length,
      itemBuilder: (context, index) {
        final customer = db.customers[index];
        return _buildCustomerCard(customer, auth, db);
      },
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, AuthService auth, DatabaseService db) {
    bool hasBalance = customer.advanceBalance > 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: hasBalance ? Colors.red.shade100 : Colors.green.shade100,
          child: Text(customer.name[0], style: TextStyle(color: hasBalance ? Colors.red : Colors.green)),
        ),
        title: Text(customer.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(customer.phone),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('₹${customer.advanceBalance.toStringAsFixed(0)}', 
              style: TextStyle(color: hasBalance ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(Icons.call, 'Call', Colors.green, () => launchUrl(Uri.parse('tel:${customer.phone}'))),
                _actionButton(Icons.message, 'SMS', Colors.deepOrange, () => _sendSMS(customer)),
                _actionButton(Icons.edit, 'Edit', Colors.blue, () => _showCustomerDialog(context, auth, db, customer: customer)),
                _actionButton(Icons.payments, 'Pay', Colors.orange, () => _showPaymentDialog(customer, auth, db)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _sendSMS(CustomerModel customer) async {
    final String message = "नमस्कार ${customer.name}, चिकन मार्ट मध्ये आपले स्वागत आहे! आपली सध्याची थकबाकी ₹${customer.advanceBalance.toStringAsFixed(0)} आहे.";
    final Uri smsUri = Uri.parse('sms:${customer.phone}?body=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch SMS app")));
    }
  }

  void _showCustomerDialog(BuildContext context, AuthService auth, DatabaseService db, {CustomerModel? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final phoneController = TextEditingController(text: customer?.phone);
    final emailController = TextEditingController(text: customer?.email);
    final addressController = TextEditingController(text: customer?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                final newCustomer = CustomerModel(
                  id: customer?.id ?? '',
                  name: nameController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                  address: addressController.text,
                  createdAt: customer?.createdAt ?? DateTime.now(),
                  advanceBalance: customer?.advanceBalance ?? 0.0,
                  nextPaymentDate: customer?.nextPaymentDate,
                );
                bool success;
                if (customer == null) {
                  success = await db.addCustomer(newCustomer, auth);
                } else {
                  success = await db.updateCustomer(newCustomer, auth);
                }
                if (success) Navigator.pop(context);
              }
            },
            child: Text(customer == null ? 'Add' : 'Update'),
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
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Amount', prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                double payAmount = double.parse(controller.text);
                final updatedCust = CustomerModel(
                  id: customer.id,
                  name: customer.name,
                  phone: customer.phone,
                  email: customer.email,
                  address: customer.address,
                  advanceBalance: customer.advanceBalance - payAmount,
                  nextPaymentDate: customer.nextPaymentDate,
                  createdAt: customer.createdAt,
                );
                await db.updateCustomer(updatedCust, auth);
                Navigator.pop(context);
              }
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(DatabaseService db, AuthService auth) {
    final query = _searchController.text.toLowerCase();
    final dbMatches = db.customers.where((c) => c.name.toLowerCase().contains(query) || c.phone.contains(query)).toList();
    final contactMatches = _contacts.where((c) => c.displayName.toLowerCase().contains(query) || (c.phones.isNotEmpty && c.phones.first.number.replaceAll(RegExp(r'\D'), '').contains(query))).toList();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (dbMatches.isNotEmpty) ...[
          _buildSectionHeader('Shop Database'),
          ...dbMatches.map((c) => _buildCustomerCard(c, auth, db)),
        ],
        if (contactMatches.isNotEmpty) ...[
          _buildSectionHeader('Phone Contacts'),
          ...contactMatches.map((c) => _buildContactItem(c, auth, db)),
        ],
      ],
    );
  }

  Widget _buildContactItem(Contact contact, AuthService auth, DatabaseService db) {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : 'No number';
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Icon(Icons.person_add, color: Colors.grey)),
        title: Text(contact.displayName),
        subtitle: Text(phone),
        trailing: ElevatedButton(
          child: Text('ADD TO SHOP'),
          onPressed: () => _addContactToDatabase(contact, auth, db),
        ),
      ),
    );
  }

  void _addContactToDatabase(Contact contact, AuthService auth, DatabaseService db) async {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number.replaceAll(RegExp(r'\D'), '') : '';
    final newCust = CustomerModel(id: '', name: contact.displayName, phone: phone, createdAt: DateTime.now());
    bool success = await db.addCustomer(newCust, auth);
    if (success) {
      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${contact.displayName} added!')));
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F51B5), fontSize: 12)),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
