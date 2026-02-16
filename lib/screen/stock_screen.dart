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
        title: Text('Stock & Inventory', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () => db.fetchStocks(auth)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
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
                      return _buildStockItem(item, db, auth);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem(StockModel item, DatabaseService db, AuthService auth) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(item.emoji, style: TextStyle(fontSize: 32)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Category: ${item.category}', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item.currentStock} ${item.unit}', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: item.isOutOfStock ? Colors.red : Colors.green)),
                    Text('In Stock', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showMovementDialog(context, item, 'in', db, auth),
                  icon: Icon(Icons.add, size: 18),
                  label: Text('STOCK IN'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showMovementDialog(context, item, 'out', db, auth),
                  icon: Icon(Icons.remove, size: 18),
                  label: Text('STOCK OUT'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMovementDialog(BuildContext context, StockModel item, String type, DatabaseService db, AuthService auth) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock ${type.toUpperCase()} - ${item.productName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Quantity in ${item.unit}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                bool success = await db.recordStockMovement(item.productId, double.parse(controller.text), type, auth);
                if (success) Navigator.pop(context);
              }
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
