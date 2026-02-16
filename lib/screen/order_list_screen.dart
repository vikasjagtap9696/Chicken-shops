import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/sale_model.dart';

class OrderListScreen extends StatefulWidget {
  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      Provider.of<DatabaseService>(context, listen: false).fetchAllOrders(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order History', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFE64A19),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => db.fetchAllOrders(auth),
          ),
        ],
      ),
      body: db.isLoading
          ? Center(child: CircularProgressIndicator())
          : db.sales.isEmpty
              ? Center(child: Text('No orders found.'))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: db.sales.length,
                  itemBuilder: (context, index) {
                    final sale = db.sales[index];
                    return _buildOrderCard(sale);
                  },
                ),
    );
  }

  Widget _buildOrderCard(SaleModel sale) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(sale.billNumber, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(sale.createdAt)),
        trailing: Text('₹${sale.grandTotal.toStringAsFixed(2)}', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${sale.customerName ?? 'Walk-in'}', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Payment Mode: ${sale.paymentMode.toUpperCase()}'),
                Divider(),
                ...sale.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.productName} x ${item.quantity}'),
                      Text('₹${item.total.toStringAsFixed(2)}'),
                    ],
                  ),
                )).toList(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
