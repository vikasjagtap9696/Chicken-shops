import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/stock_model.dart';
import '../models/customer_model.dart';

class BillingScreen extends StatefulWidget {
  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  CustomerModel? selectedCustomer;
  List<Map<String, dynamic>> cartItems = [];
  double discount = 0;
  String paymentMethod = 'cash';

  final TextEditingController _productSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // स्क्रीन उघडताच प्रॉडक्ट्स आणि कस्टमर्स लोड करा
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final db = Provider.of<DatabaseService>(context, listen: false);
      db.fetchStocks(auth);
      db.fetchCustomers(auth);
    });
  }

  double get subtotal => cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get grandTotal => subtotal - discount;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Billing'),
        backgroundColor: Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => db.fetchStocks(auth), // मॅन्युअली लोड करण्यासाठी
          ),
        ],
      ),
      body: Column(
        children: [
          // ग्राहक निवडणे
          _buildCustomerTile(db),
          
          // प्रॉडक्ट सर्च बार
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _productSearchController,
              decoration: InputDecoration(
                hintText: 'Search Chicken Items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // प्रॉडक्ट लिस्ट किंवा कार्ट व्ह्यू
          Expanded(
            child: _productSearchController.text.isEmpty 
              ? _buildCartView() 
              : _buildProductList(db),
          ),

          // बिल सारांश
          _buildOrderSummary(db, auth),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(DatabaseService db) {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.person)),
      title: Text(selectedCustomer?.name ?? "Walk-in Customer"),
      subtitle: Text(selectedCustomer?.phone ?? "Select a registered customer"),
      trailing: TextButton(
        onPressed: () => _showCustomerSearch(db),
        child: Text('SELECT'),
      ),
    );
  }

  Widget _buildProductList(DatabaseService db) {
    final query = _productSearchController.text.toLowerCase();
    final results = db.stocks.where((s) => s.name.toLowerCase().contains(query)).toList();

    if (results.isEmpty) return Center(child: Text('No products found.'));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          leading: Text(product.emoji, style: TextStyle(fontSize: 24)),
          title: Text(product.name),
          subtitle: Text('₹${product.sellingPrice} / ${product.unit} (Stock: ${product.quantity})'),
          trailing: ElevatedButton(
            onPressed: () => _addToCart(product),
            child: Text('ADD'),
          ),
        );
      },
    );
  }

  Widget _buildCartView() {
    if (cartItems.isEmpty) return Center(child: Text('Cart is empty. Search products to add items.'));
    return ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return ListTile(
          title: Text(item['name']),
          subtitle: Text('₹${item['price']} x ${item['quantity']} ${item['unit']}'),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => setState(() => cartItems.removeAt(index)),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary(DatabaseService db, AuthService auth) {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('₹${grandTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty ? null : () => _placeOrder(db, auth),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF50)),
              child: Text('Confirm Order', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(StockModel product) {
    setState(() {
      cartItems.add({
        'productId': product.id,
        'name': product.name,
        'price': product.sellingPrice,
        'quantity': 1.0,
        'unit': product.unit,
      });
      _productSearchController.clear();
    });
  }

  void _showCustomerSearch(DatabaseService db) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: db.customers.length,
        itemBuilder: (context, index) {
          final c = db.customers[index];
          return ListTile(
            title: Text(c.name),
            subtitle: Text(c.phone),
            onTap: () {
              setState(() => selectedCustomer = c);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Future<void> _placeOrder(DatabaseService db, AuthService auth) async {
    final orderData = {
      "customerId": selectedCustomer?.id,
      "items": cartItems.map((item) => {
        "productId": int.parse(item['productId']),
        "quantity": item['quantity']
      }).toList(),
      "paymentMethod": "cash",
    };

    bool success = await db.createSale(orderData, auth);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order Saved!')));
      setState(() => cartItems.clear());
    }
  }
}
