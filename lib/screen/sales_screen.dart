import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/sale_model.dart';

class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedFilter = 'All'; // All, Cash, Online, Credit

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Sales Report', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFE64A19),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<DatabaseService>(
        builder: (context, db, child) {
          final filteredSales = _selectedFilter == 'All' 
              ? db.sales 
              : db.sales.where((s) => s.paymentMode.toLowerCase() == _selectedFilter.toLowerCase()).toList();

          double totalFilteredSales = filteredSales.fold(0, (sum, item) => sum + item.grandTotal);

          return Column(
            children: [
              _buildFilterBar(),
              _buildSummaryHeader(totalFilteredSales),
              Expanded(
                child: filteredSales.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: filteredSales.length,
                      itemBuilder: (context, index) => _buildSaleCard(filteredSales[index]),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: Color(0xFFE64A19),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: ['All', 'Cash', 'Online', 'Credit'].map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter, style: TextStyle(color: isSelected ? Colors.orange : Colors.white, fontSize: 12)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = filter),
              selectedColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryHeader(double total) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE64A19), Color(0xFFFF7043)]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text('TOTAL SALES ($_selectedFilter)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('₹ ${total.toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons. analytics_outlined, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text('No sales records for $_selectedFilter', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSaleCard(SaleModel sale) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(sale.customerName ?? 'Walk-in', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('₹${sale.grandTotal.toStringAsFixed(0)}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(DateFormat('dd MMM yyyy • hh:mm a').format(sale.createdAt), style: TextStyle(fontSize: 11)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildBadge(sale.paymentMode.toUpperCase(), Colors.blue),
                _buildBadge('Order #${sale.billNumber}', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
