import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final status = await Permission.contacts.request();
    setState(() {
      _isPermissionGranted = status.isGranted;
    });
    if (_isPermissionGranted) {
      _fetchDeviceContacts();
    }
  }

  Future<void> _fetchDeviceContacts() async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    setState(() {
      _contacts = contacts;
    });
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
          hintText: 'Search Database or Phone Contacts...',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildCustomerList(DatabaseService db, AuthService auth) {
    if (db.customers.isEmpty) return Center(child: Text('No customers found.'));
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
    bool hasBalance = customer.advanceBalance != 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: Color(0xFF3F51B5), child: Text(customer.name[0])),
        title: Text(customer.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(customer.phone),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Remaining', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('₹${customer.advanceBalance.toStringAsFixed(0)}', 
              style: TextStyle(
                color: customer.advanceBalance > 0 ? Colors.red : Colors.green, 
                fontWeight: FontWeight.bold,
                fontSize: 16
              )),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(Icons.call, 'Call', Colors.green, () => launch('tel:${customer.phone}')),
                if (hasBalance) 
                  _actionButton(Icons.notifications_active, 'Remind', Colors.deepOrange, () => _sendPaymentReminder(customer)),
                _actionButton(Icons.edit, 'Edit', Colors.blue, () => _showEditDialog(customer, auth, db)),
                _actionButton(Icons.delete, 'Delete', Colors.red, () => _showDeleteConfirm(customer.id, auth, db)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _sendPaymentReminder(CustomerModel customer) async {
    final String message = 
        "नमस्कार ${customer.name}, आपल्या चिकन मार्टचे ₹${customer.advanceBalance.toStringAsFixed(0)} रुपये येणे बाकी आहे. कृपया लवकरात लवकर जमा करावे. धन्यवाद!";
    
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: customer.phone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open SMS app')));
    }
  }

  Widget _buildSearchResults(DatabaseService db, AuthService auth) {
    final query = _searchController.text.toLowerCase();
    final dbMatches = db.customers.where((c) => c.name.toLowerCase().contains(query) || c.phone.contains(query)).toList();
    final contactMatches = _contacts.where((c) => c.displayName.toLowerCase().contains(query) || (c.phones.isNotEmpty && c.phones.first.number.contains(query))).toList();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (dbMatches.isNotEmpty) ...[
          _buildSectionHeader('Database Results'),
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
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Icon(Icons.person_add, color: Colors.grey)),
      title: Text(contact.displayName),
      subtitle: Text(phone),
      trailing: ElevatedButton(
        child: Text('ADD'),
        onPressed: () => _addContactToDatabase(contact, auth, db),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12)),
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

  void _addContactToDatabase(Contact contact, AuthService auth, DatabaseService db) async {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number.replaceAll(RegExp(r'\D'), '') : '';
    final newCust = CustomerModel(id: '', name: contact.displayName, phone: phone, createdAt: DateTime.now());
    bool success = await db.addCustomer(newCust, auth);
    if (success) {
      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${contact.displayName} added!')));
    }
  }

  void _showEditDialog(CustomerModel customer, AuthService auth, DatabaseService db) { /* ... edit logic ... */ }
  void _showDeleteConfirm(String id, AuthService auth, DatabaseService db) { /* ... delete logic ... */ }
}
