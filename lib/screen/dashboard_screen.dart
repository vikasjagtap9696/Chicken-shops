import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'billing_screen.dart';
import 'sales_screen.dart';
import 'stock_screen.dart';
import 'customer_screen.dart';
import 'staff_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final db = Provider.of<DatabaseService>(context, listen: false);
      db.fetchSales(auth);
      db.fetchStocks(auth);
      db.fetchRevenueSummary(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(auth),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(db),
                  SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildActionGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BillingScreen()),
        ),
        backgroundColor: Color(0xFFE64A19),
        icon: Icon(Icons.add_shopping_cart, color: Colors.white),
        label: Text('New Bill', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildModernAppBar(AuthService auth) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFFE64A19),
      elevation: 0,
      title: Text('Chicken Mart', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: () => _showProfileOptions(auth),
            child: Hero(
              tag: 'profile_pic',
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  auth.currentUser?.name[0].toUpperCase() ?? 'A',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFE64A19), Color(0xFFFF7043)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DatabaseService db) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today\'s Sales',
            '₹${db.todaySales.toStringAsFixed(0)}',
            Icons.trending_up,
            Color(0xFF4CAF50),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Stock Value',
            '₹${db.totalStockValue.toStringAsFixed(0)}',
            Icons.inventory_2,
            Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'title': 'Billing', 'icon': FontAwesomeIcons.fileInvoice, 'color': Color(0xFF4CAF50), 'page': BillingScreen()},
      {'title': 'Sales Report', 'icon': FontAwesomeIcons.chartLine, 'color': Color(0xFF2196F3), 'page': SalesScreen()},
      {'title': 'Inventory', 'icon': FontAwesomeIcons.boxesStacked, 'color': Color(0xFF9C27B0), 'page': StockScreen()},
      {'title': 'Customers', 'icon': FontAwesomeIcons.users, 'color': Color(0xFFE64A19), 'page': CustomerScreen()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => items[index]['page'])),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(items[index]['icon'], color: items[index]['color'], size: 28),
                SizedBox(height: 12),
                Text(
                  items[index]['title'],
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3436)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileOptions(AuthService auth) {
    final bool isAdmin = auth.currentUser?.role == 'admin';

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(radius: 25, backgroundColor: Color(0xFFE64A19), child: Text(auth.currentUser?.name[0] ?? 'A', style: TextStyle(color: Colors.white, fontSize: 20))),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.currentUser?.name ?? 'Admin', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (isAdmin) Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text('ADMIN', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 32),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.blue),
              title: Text('Edit Profile'),
              onTap: () { Navigator.pop(context); _showEditProfileDialog(auth); },
            ),
            if (isAdmin) ListTile(
              leading: Icon(Icons.people_outline, color: Colors.teal),
              title: Text('Manage Staff'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => StaffScreen())); },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(AuthService auth) {
    final nameController = TextEditingController(text: auth.currentUser?.name);
    final shopController = TextEditingController(text: auth.currentUser?.shopName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Full Name')),
            TextField(controller: shopController, decoration: InputDecoration(labelText: 'Shop Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE64A19)),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
