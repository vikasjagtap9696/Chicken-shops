import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStaff();
    });
  }

  void _refreshStaff() {
    final auth = Provider.of<AuthService>(context, listen: false);
    Provider.of<DatabaseService>(context, listen: false).fetchStaff(auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);
    final bool isAdmin = auth.currentUser?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Staff Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStaff,
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () => _showAddStaffDialog(context, auth, db),
            ),
        ],
      ),
      body: db.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: () async => _refreshStaff(),
              child: db.staff.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No staff members found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: db.staff.length,
                      itemBuilder: (context, index) {
                        final member = db.staff[index];
                        final bool isCurrentUser = member.id == auth.currentUser?.id;
                        
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.teal.shade50,
                              child: Text(
                                member.name[0].toUpperCase(),
                                style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member.name,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                if (isCurrentUser)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                                    child: const Text('YOU', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(member.email, style: TextStyle(color: Colors.grey.shade600)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: member.role == 'admin' ? Colors.red.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    member.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: member.role == 'admin' ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: isAdmin && !isCurrentUser
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _showDeleteConfirm(context, member, auth, db),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  void _showDeleteConfirm(BuildContext context, UserModel member, AuthService auth, DatabaseService db) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff?'),
        content: Text('Are you sure you want to remove ${member.name}? They will no longer have access to the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              bool success = await db.deleteStaff(member.id, auth);
              if (!context.mounted) return;
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.name} removed successfully'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to remove staff member'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add New Staff', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Initial Password', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Assign Role:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      items: ['staff', 'admin'].map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase(), style: TextStyle(color: role == 'admin' ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedRole = val!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }
                final data = {
                  "name": nameController.text,
                  "email": emailController.text,
                  "password": passwordController.text,
                  "role": selectedRole
                };
                bool success = await db.addStaff(data, auth);
                if (!context.mounted) return;
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff added successfully'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add staff'), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
              child: const Text('Add Staff', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
