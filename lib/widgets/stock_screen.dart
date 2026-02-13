import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/stock_model.dart';
import '../widgets/custom_button.dart';

class StockScreen extends StatefulWidget {
  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'सर्व';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('स्टॉक व्यवस्थापन'),
        backgroundColor: Color(0xFF9C27B0),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddStockDialog(),
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<DatabaseService>(
        builder: (context, db, child) {
          var stocks = db.stocks;

          // Filter by category
          if (_selectedCategory != 'सर्व') {
            stocks = stocks.where((s) => s.category == _selectedCategory).toList();
          }

          // Filter by search
          if (_searchController.text.isNotEmpty) {
            stocks = stocks
                .where((s) => s.name.toLowerCase().contains(_searchController.text.toLowerCase()))
                .toList();
          }

          return Column(
            children: [
              // Search Bar
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'स्टॉक शोधा...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),

              // Category Filter
              Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('सर्व', _selectedCategory == 'सर्व'),
                    _buildCategoryChip('फुल चिकन', _selectedCategory == 'फुल चिकन'),
                    _buildCategoryChip('बर्गर', _selectedCategory == 'बर्गर'),
                    _buildCategoryChip('स्टार्टर्स', _selectedCategory == 'स्टार्टर्स'),
                    _buildCategoryChip('बोनलेस', _selectedCategory == 'बोनलेस'),
                  ],
                ),
              ),

              // Low Stock Alert
              if (db.lowStockItems.isNotEmpty)
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'लो स्टॉक अलर्ट!',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            Text(
                              '${db.lowStockItems.length} प्रॉडक्ट्स कमी स्टॉक',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Show low stock items
                        },
                        child: Text('पहा'),
                      ),
                    ],
                  ),
                ),

              // Stock Summary
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'एकूण आयटम्स',
                        '${stocks.length}',
                        Icons.inventory,
                        Colors.purple,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'एकूण स्टॉक व्हॅल्यू',
                        '₹ ${db.totalStockValue.toStringAsFixed(0)}',
                        Icons.currency_rupee,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Stock List
              Expanded(
                child: stocks.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'कोणताही स्टॉक उपलब्ध नाही',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'नवीन प्रॉडक्ट अ‍ॅड करा',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final stock = stocks[index];
                    return _buildStockCard(stock);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = label;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Color(0xFF9C27B0).withOpacity(0.2),
        checkmarkColor: Color(0xFF9C27B0),
        labelStyle: GoogleFonts.poppins(
          color: isSelected ? Color(0xFF9C27B0) : Colors.grey[700],
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
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
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
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(StockModel stock) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: stock.isLowStock
              ? Border.all(color: Colors.red.shade300, width: 1)
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Product Emoji
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        stock.emoji,
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stock.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                stock.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ख.किं: ₹${stock.purchasePrice} | वि.किं: ₹${stock.sellingPrice}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'नफा: ₹${stock.profit.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${stock.profitMargin.toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Stock Quantity & Actions
              Row(
                children: [
                  // Stock Info
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: stock.isLowStock ? Colors.red.shade50 : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: stock.isLowStock ? Colors.red : Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'स्टॉक: ${stock.quantity} ${stock.unit}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: stock.isLowStock ? FontWeight.bold : FontWeight.normal,
                              color: stock.isLowStock ? Colors.red : Colors.grey[800],
                            ),
                          ),
                          if (stock.isLowStock) ...[
                            SizedBox(width: 8),
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: Colors.red,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),

                  // Update Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed: () => _showEditStockDialog(stock),
                    ),
                  ),
                  SizedBox(width: 4),

                  // Add Stock Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add_shopping_cart, size: 18, color: Colors.green),
                      onPressed: () => _showAddQuantityDialog(stock),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStockDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'नवीन प्रॉडक्ट',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              // Add form fields here
              CustomButton(
                text: 'प्रॉडक्ट जोडा',
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStockDialog(StockModel stock) {
    // Edit dialog
  }

  void _showAddQuantityDialog(StockModel stock) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'स्टॉक वाढवा',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text('${stock.name} मध्ये स्टॉक वाढवा'),
              SizedBox(height: 24),
              CustomButton(
                text: 'अ‍ॅड करा',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}