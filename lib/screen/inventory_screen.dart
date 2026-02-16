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
        backgroundColor: Colors.blueGrey,
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
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
          Expanded(
            child: db.isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: db.stocks.length,
                    itemBuilder: (context, index) {
                      final item = db.stocks[index];
                      if (_searchController.text.isNotEmpty && !item.productName.toLowerCase().contains(_searchController.text.toLowerCase())) {
                        return SizedBox.shrink();
                      }
                      return _buildProductCard(item, db, auth);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(StockModel item, DatabaseService db, AuthService auth) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(item.emoji, style: TextStyle(fontSize: 32)),
        title: Text(item.productName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Price: ₹${item.pricePerUnit} | Unit: ${item.unit}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showProductDialog(context, auth, db, stock: item),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Product Name')),
              TextField(controller: priceController, decoration: InputDecoration(labelText: 'Price Per Unit'), keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                value: category,
                items: ['chicken', 'mutton', 'egg', 'fish', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                onChanged: (val) => category = val!,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              DropdownButtonFormField<String>(
                value: unit,
                items: ['kg', 'piece', 'dozen'].map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase()))).toList(),
                onChanged: (val) => unit = val!,
                decoration: InputDecoration(labelText: 'Unit'),
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
            child: Text('Save'),
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
        content: Text('This will permanently remove the product.'),
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
