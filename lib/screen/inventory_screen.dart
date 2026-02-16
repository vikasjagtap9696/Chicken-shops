import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/stock_model.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Inventory Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () => db.fetchStocks(auth)),
          IconButton(
            icon: Icon(Icons.add_box),
            onPressed: () => _showProductDialog(context, auth, db),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(db),
          Expanded(
            child: db.isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildProductList(db, auth),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(DatabaseService db) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) => setState(() {}),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'chicken', 'mutton', 'egg', 'fish', 'other'].map((cat) {
                bool isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat.toUpperCase(), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                    selectedColor: Colors.orangeAccent,
                    backgroundColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductList(DatabaseService db, AuthService auth) {
    final query = _searchController.text.toLowerCase();
    final filtered = db.stocks.where((item) {
      final matchesSearch = item.productName.toLowerCase().contains(query);
      final matchesCat = _selectedCategory == 'All' || item.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCat;
    }).toList();

    if (filtered.isEmpty) return Center(child: Text('No products found.'));

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildProductCard(filtered[index], db, auth);
      },
    );
  }

  Widget _buildProductCard(StockModel item, DatabaseService db, AuthService auth) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Text(item.emoji, style: TextStyle(fontSize: 24)),
        ),
        title: Text(item.productName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₹${item.pricePerUnit} / ${item.unit}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            Text('Category: ${item.category.toUpperCase()}', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_note, color: Colors.blue),
              onPressed: () => _showProductDialog(context, auth, db, stock: item),
            ),
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: Colors.red),
              onPressed: () => _showDeleteConfirm(context, auth, db, item.productId),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog(BuildContext context, AuthService auth, DatabaseService db, {StockModel? stock}) {
    final nameController = TextEditingController(text: stock?.productName);
    final priceController = TextEditingController(text: stock?.pricePerUnit.toString());
    String category = stock?.category ?? 'chicken';
    String unit = stock?.unit ?? 'kg';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(stock == null ? 'Add New Product' : 'Edit Product'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Product Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              SizedBox(height: 15),
              TextField(controller: priceController, decoration: InputDecoration(labelText: 'Price Per Unit', prefixText: '₹ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: category,
                items: ['chicken', 'mutton', 'egg', 'fish', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                onChanged: (val) => category = val!,
                decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: unit,
                items: ['kg', 'piece', 'dozen'].map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase()))).toList(),
                onChanged: (val) => unit = val!,
                decoration: InputDecoration(labelText: 'Unit', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                "name": nameController.text,
                "pricePerUnit": double.parse(priceController.text),
                "category": category,
                "unit": unit,
              };
              bool success;
              if (stock == null) {
                success = await db.addStock(data, auth);
              } else {
                success = await db.updateStock(stock.productId, data, auth);
              }
              if (success) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Save Product', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, AuthService auth, DatabaseService db, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product?'),
        content: Text('This will permanently remove the product from your inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No')),
          ElevatedButton(
            onPressed: () async {
              bool success = await db.deleteStock(id, auth);
              if (success) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
