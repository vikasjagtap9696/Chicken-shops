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
  String _selectedFilter = 'All'; // All, Cash, Online, Credit
  DateTime? _selectedDate;

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

    // Apply Filters locally
    List<SaleModel> filteredOrders = db.sales.where((order) {
      bool matchesPayment = _selectedFilter == 'All' || 
          order.paymentMode.toLowerCase() == _selectedFilter.toLowerCase();
      
      bool matchesDate = _selectedDate == null || 
          (order.createdAt.year == _selectedDate!.year &&
           order.createdAt.month == _selectedDate!.month &&
           order.createdAt.day == _selectedDate!.day);
           
      return matchesPayment && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Order History', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFE64A19),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, size: 20),
            onPressed: () => _pickDate(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedFilter = 'All';
                _selectedDate = null;
              });
              db.fetchAllOrders(auth);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}'),
                onDeleted: () => setState(() => _selectedDate = null),
              ),
            ),
          Expanded(
            child: db.isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFFE64A19)))
                : filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text('No matching orders found.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final sale = filteredOrders[index];
                          return _buildOrderListItem(sale);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _filterChip('All'),
          _filterChip('Cash'),
          _filterChip('Online'),
          _filterChip('Credit'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _selectedFilter = label);
        },
        selectedColor: Color(0xFFE64A19),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _buildOrderListItem(SaleModel sale) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Color(0xFFE64A19).withOpacity(0.1),
          child: Icon(Icons.shopping_bag, color: Color(0xFFE64A19), size: 20),
        ),
        title: Text(
          sale.customerName ?? 'Walk-in Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy • hh:mm a').format(sale.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Order ID: ${sale.billNumber}',
                style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${sale.grandTotal.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade700),
            ),
            Text(
              sale.paymentMode.toUpperCase(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[500]),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800])),
                Divider(),
                ...sale.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} x ${item.quantity}',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                      Text(
                        '₹${item.total.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                )).toList(),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text('₹${sale.subtotal.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                if (sale.discount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discount', style: TextStyle(color: Colors.red[400], fontSize: 12)),
                      Text('-₹${sale.discount.toStringAsFixed(2)}', style: TextStyle(color: Colors.red[400], fontSize: 12)),
                    ],
                  ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('₹${sale.grandTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
