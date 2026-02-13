import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class StaffScreen extends StatefulWidget {
  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      Provider.of<DatabaseService>(context, listen: false).fetchStaff(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () => _showAddStaffDialog(context, auth, db),
          ),
        ],
      ),
      body: db.isLoading
          ? Center(child: CircularProgressIndicator())
          : db.staff.isEmpty
              ? Center(child: Text('No staff members found.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: db.staff.length,
                  itemBuilder: (context, index) {
                    final member = db.staff[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(member.name[0].toUpperCase(), style: TextStyle(color: Colors.teal)),
                        ),
                        title: Text(member.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${member.email}\nRole: ${member.role}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => db.deleteStaff(member.id, auth),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddStaffDialog(BuildContext context, AuthService auth, DatabaseService db) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'staff';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Full Name')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              items: ['staff', 'admin'].map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => selectedRole = val!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                "name": nameController.text,
                "email": emailController.text,
                "password": passwordController.text,
                "role": selectedRole
              };
              bool success = await db.addStaff(data, auth);
              if (success) Navigator.pop(context);
            },
            child: Text('Add Staff'),
          ),
        ],
      ),
    );
  }
}
