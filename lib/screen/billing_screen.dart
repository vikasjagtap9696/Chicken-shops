import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  String paymentMethod = 'cash';
  double amountReceived = 0.0;
  DateTime? nextPaymentDate;

  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _amountReceivedController = TextEditingController();
  
  bool _showCustomerResults = false;

  @override
  void initState() {
    super.initState();
    selectedCustomer = null; 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final db = Provider.of<DatabaseService>(context, listen: false);
      db.fetchStocks(auth);
      db.fetchCustomers(auth);
    });
  }

  double get subtotal => cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get grandTotal => subtotal;
  double get balanceAmount => grandTotal - amountReceived;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Billing', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTopSearchSection(db),
          Expanded(
            child: _buildProductGrid(db),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCheckout(db, auth),
    );
  }

  Widget _buildTopSearchSection(DatabaseService db) {
    final query = _customerSearchController.text.toLowerCase();
    final results = db.customers.where((c) => 
      c.name.toLowerCase().contains(query) || 
      c.phone.contains(query)
    ).toList();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _customerSearchController,
            onChanged: (val) => setState(() => _showCustomerResults = val.isNotEmpty),
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Customer...',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.person_search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (_showCustomerResults && selectedCustomer == null)
            _buildCustomerSearchResults(results),
          
          SizedBox(height: 12),
          TextField(
            controller: _productSearchController,
            onChanged: (v) => setState(() {}),
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Item...',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.shopping_bag, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSearchResults(List<CustomerModel> results) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      constraints: BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: results.isEmpty 
        ? ListTile(title: Text('Not Found'))
        : ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final c = results[index];
              return ListTile(
                dense: true,
                title: Text(c.name, style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  setState(() {
                    selectedCustomer = c;
                    _customerSearchController.text = c.name;
                    _showCustomerResults = false;
                  });
                },
              );
            },
          ),
    );
  }

  Widget _buildProductGrid(DatabaseService db) {
    final query = _productSearchController.text.toLowerCase();
    final results = db.stocks.where((s) => s.productName.toLowerCase().contains(query)).toList();

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return InkWell(
          onTap: () => _addToCart(product),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(product.emoji, style: TextStyle(fontSize: 32)),
                Text(product.productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
                Text('₹${product.pricePerUnit}', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomCheckout(DatabaseService db, AuthService auth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected Items (Cart)
          if (cartItems.isNotEmpty)
            _buildCartPreview(),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Payable', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text('₹${grandTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                SizedBox(height: 15),
                _buildPaymentOptions(),
                SizedBox(height: 15),
                _buildReceivedAmountAndDate(),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: cartItems.isEmpty ? null : () => _placeOrder(db, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text('Confirm & Print Bill', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPreview() {
    return Container(
      maxHeight: 120,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item['name']} x ${item['quantity']}', style: TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text('₹${item['total'] ?? (item['price'] * item['quantity'])}', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => cartItems.removeAt(index)),
                      child: Icon(Icons.remove_circle, color: Colors.red, size: 20),
                    )
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Row(
      children: [
        _paymentButton('cash', Icons.payments, Colors.green),
        SizedBox(width: 10),
        _paymentButton('online', Icons.qr_code, Colors.blue),
        SizedBox(width: 10),
        _paymentButton('credit', Icons.history, Colors.orange),
      ],
    );
  }

  Widget _paymentButton(String mode, IconData icon, Color color) {
    bool selected = paymentMethod == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          paymentMethod = mode;
          if (mode == 'credit') {
            amountReceived = 0;
            _amountReceivedController.text = "0";
          }
        }),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            border: Border.all(color: selected ? color : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : color),
              SizedBox(height: 4),
              Text(mode.toUpperCase(), style: TextStyle(fontSize: 10, color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedAmountAndDate() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _amountReceivedController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amt Paid',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (v) => setState(() => amountReceived = double.tryParse(v) ?? 0.0),
          ),
        ),
        if (balanceAmount > 0 && selectedCustomer != null) ...[
          SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _selectNextPaymentDate,
              icon: Icon(Icons.calendar_month, size: 18),
              label: Text(nextPaymentDate == null ? 'SET DATE' : DateFormat('dd MMM').format(nextPaymentDate!)),
              style: OutlinedButton.styleFrom(
                foregroundColor: nextPaymentDate != null ? Colors.green : Colors.orange,
                side: BorderSide(color: nextPaymentDate != null ? Colors.green : Colors.orange),
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]
      ],
    );
  }

  Future<void> _selectNextPaymentDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() => nextPaymentDate = picked);
  }

  void _addToCart(StockModel product) {
    setState(() {
      int idx = cartItems.indexWhere((item) => item['productId'] == product.productId);
      if (idx != -1) {
        cartItems[idx]['quantity'] += 0.5; 
      } else {
        cartItems.add({'productId': product.productId, 'name': product.productName, 'price': product.pricePerUnit, 'quantity': 1.0, 'unit': product.unit});
      }
    });
  }

  Future<void> _placeOrder(DatabaseService db, AuthService auth) async {
    final orderData = {
      "customerId": selectedCustomer?.id,
      "items": cartItems.map((item) => {"productId": int.parse(item['productId']), "quantity": item['quantity']}).toList(),
      "paymentMethod": paymentMethod,
      "amountPaid": amountReceived,
      "totalAmount": grandTotal,
      "nextPaymentDate": nextPaymentDate?.toIso8601String(),
    };
    bool success = await db.createSale(orderData, auth);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bill Generated!'), backgroundColor: Colors.green));
      setState(() {
        cartItems.clear();
        selectedCustomer = null;
        _customerSearchController.clear();
        _amountReceivedController.clear();
        nextPaymentDate = null;
      });
    }
  }
}
