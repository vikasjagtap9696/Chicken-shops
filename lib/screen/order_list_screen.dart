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
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // All, Cash, Online, Udhari
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      Provider.of<DatabaseService>(context, listen: false).fetchAllOrders(auth);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    // Apply Filters locally
    List<SaleModel> filteredOrders = db.sales.where((order) {
      // Search Filter
      final query = _searchController.text.toLowerCase();
      bool matchesSearch = (order.customerName?.toLowerCase().contains(query) ?? false) || 
                           order.billNumber.toLowerCase().contains(query);
      
      if (!matchesSearch) return false;

      // Payment Filter
      bool matchesPayment = true;
      if (_selectedFilter == 'Udhari') {
        matchesPayment = order.hasBalance;
      } else if (_selectedFilter != 'All') {
        matchesPayment = order.paymentMode.toLowerCase() == _selectedFilter.toLowerCase();
      }
      
      if (!matchesPayment) return false;

      // Date Filter
      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        matchesDate = order.createdAt.isAfter(start) && order.createdAt.isBefore(end);
      } else if (_startDate != null) {
        matchesDate = order.createdAt.year == _startDate!.year &&
                      order.createdAt.month == _startDate!.month &&
                      order.createdAt.day == _startDate!.day;
      }
           
      return matchesDate;
    }).toList();

    // Calculate Totals for Footer
    double totalUdhariAmount = 0;
    int pendingOrdersCount = 0; // Changed to count entries instead of unique persons for better accuracy
    for (var order in filteredOrders) {
      if (order.hasBalance) {
        totalUdhariAmount += order.balanceAmount;
        pendingOrdersCount++;
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Order History', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFE64A19),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, size: 20),
            onPressed: () => _pickDateRange(context),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedFilter = 'All';
                _startDate = null;
                _endDate = null;
                _searchController.clear();
              });
              db.fetchAllOrders(auth);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          if (_startDate != null) _buildDateIndicator(),
          Expanded(
            child: db.isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFFE64A19)))
                : filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) => _buildOrderListItem(filteredOrders[index]),
                      ),
          ),
          if (filteredOrders.isNotEmpty) _buildFooter(pendingOrdersCount, totalUdhariAmount),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Color(0xFFE64A19),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search Customer or Bill No...',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(icon: Icon(Icons.clear, color: Colors.white), onPressed: () { _searchController.clear(); setState(() {}); })
            : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFooter(int orderCount, double amount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending Orders', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text('$orderCount Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total Pending Amount', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.orange.shade900),
                  SizedBox(width: 8),
                  Text(
                    _endDate == null 
                      ? 'Date: ${DateFormat('dd MMM yyyy').format(_startDate!)}'
                      : '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () => setState(() { _startDate = null; _endDate = null; }),
                    child: Icon(Icons.close, size: 16, color: Colors.orange.shade900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No matching orders found.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
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
          _filterChip('Udhari'),
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

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFE64A19),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
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
            Row(
              children: [
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
                if (sale.hasBalance) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'UDHARI: ₹${sale.balanceAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10, color: Colors.red.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${sale.grandTotal.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, 
                fontSize: 18, 
                color: sale.hasBalance ? Colors.orange.shade800 : Colors.green.shade700
              ),
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
                    Text('Amount Paid', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                    Text('₹${sale.amountPaid.toStringAsFixed(2)}', style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (sale.hasBalance)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Remaining (Udhari)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('₹${sale.balanceAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
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
