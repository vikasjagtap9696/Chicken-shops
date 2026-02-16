import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shopController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;
  late TextEditingController _fssaiController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name);
    _shopController = TextEditingController(text: user?.shopName);
    _phoneController = TextEditingController(text: user?.phone);
    _addressController = TextEditingController(text: user?.address);
    _gstController = TextEditingController(text: user?.gstNumber);
    _fssaiController = TextEditingController(text: user?.fssaiNumber);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFE64A19),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(auth),
              SizedBox(height: 30),
              _buildTextField(_nameController, 'Full Name', Icons.person),
              _buildTextField(_shopController, 'Shop Name', Icons.storefront),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
              _buildTextField(_addressController, 'Shop Address', Icons.location_on, maxLines: 2),
              _buildTextField(_gstController, 'GST Number (Optional)', Icons.description),
              _buildTextField(_fssaiController, 'FSSAI License (Optional)', Icons.verified_user),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : () => _updateProfile(auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE64A19),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: auth.isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AuthService auth) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFFE64A19).withOpacity(0.1),
            child: Text(
              auth.currentUser?.name[0].toUpperCase() ?? 'A',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFE64A19)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Color(0xFFE64A19),
              radius: 18,
              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFFE64A19)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) => value!.isEmpty ? 'Field cannot be empty' : null,
      ),
    );
  }

  Future<void> _updateProfile(AuthService auth) async {
    if (_formKey.currentState!.validate()) {
      final data = {
        "name": _nameController.text,
        "shopName": _shopController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        "gstNumber": _gstController.text,
        "fssaiNumber": _fssaiController.text,
      };

      bool success = await auth.updateProfile(data);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Update failed'), backgroundColor: Colors.red));
      }
    }
  }
}
