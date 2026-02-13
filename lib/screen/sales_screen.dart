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
  String _selectedPeriod = 'Daily';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Report'),
        backgroundColor: Color(0xFF2196F3),
      ),
      body: Consumer<DatabaseService>(
        builder: (context, db, child) {
          return Column(
            children: [
              // Period Selector
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(child: _buildPeriodButton('Daily')),
                    Expanded(child: _buildPeriodButton('Weekly')),
                    Expanded(child: _buildPeriodButton('Monthly')),
                  ],
                ),
              ),

              // Summary Cards
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Sales',
                        '₹ ${db.todaySales.toStringAsFixed(0)}',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Profit',
                        '₹ ${db.todayProfit.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Recent Sales
              Expanded(
                child: db.sales.isEmpty 
                  ? Center(child: Text('No sales records found'))
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: db.sales.length,
                      itemBuilder: (context, index) {
                        final sale = db.sales[index];
                        return _buildSaleCard(sale);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodButton(String title) {
    bool isSelected = _selectedPeriod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = title),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2196F3) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSaleCard(SaleModel sale) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sale.billNumber, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sale.paymentMode.toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('Customer: ${sale.customerName}', style: GoogleFonts.poppins(fontSize: 14)),
            Text(
              'Date: ${DateFormat('dd/MM/yyyy hh:mm a').format(sale.createdAt)}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            ...sale.items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(child: Text(item.productName, style: GoogleFonts.poppins(fontSize: 14))),
                  Text('${item.quantity}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(width: 12),
                  Text('₹${item.total}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
                ],
              ),
            )).toList(),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('₹${sale.grandTotal}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
