import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/stock_model.dart';

class StockScreen extends StatefulWidget {
  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      Provider.of<DatabaseService>(context, listen: false).fetchStocks(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF9C27B0),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => db.fetchStocks(auth),
          ),
          IconButton(
            icon: Icon(Icons.add_box),
            onPressed: () => _showAddStockDialog(context, auth, db),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: db.isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildStockList(db, auth),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search stock items...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Chicken', 'Mutton', 'Fish', 'Egg'];
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategory == categories[index];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = categories[index]),
              selectedColor: Color(0xFF9C27B0).withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? Color(0xFF9C27B0) : Colors.black),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockList(DatabaseService db, AuthService auth) {
    var items = db.stocks;
    
    if (_selectedCategory != 'All') {
      items = items.where((i) => i.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      items = items.where((i) => i.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }

    if (items.isEmpty) return Center(child: Text('No stock items found.'));

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Text(item.emoji, style: TextStyle(fontSize: 30)),
            title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Price: ₹${item.sellingPrice} | Stock: ${item.quantity} ${item.unit}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => db.deleteStock(item.id, auth)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddStockDialog(BuildContext context, AuthService auth, DatabaseService db) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();
    String category = 'chicken';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Product Name')),
            TextField(controller: priceController, decoration: InputDecoration(labelText: 'Price Per Unit'), keyboardType: TextInputType.number),
            TextField(controller: qtyController, decoration: InputDecoration(labelText: 'Initial Stock'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                "name": nameController.text,
                "pricePerUnit": double.parse(priceController.text),
                "category": category,
                "quantity": double.parse(qtyController.text),
              };
              bool success = await db.addStock(data, auth);
              if (success) Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
