import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getProfile();
      setState(() {
        _profileData = data;
        _nameController.text = data['full_name'] ?? '';
        _addressController.text = data['address'] ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await ApiService().updateProfile(
        fullName: _nameController.text,
        address: _addressController.text,
        fcmToken: _profileData?['fcm_token'] ?? 'UPDATED_FCM_TOKEN', 
      );
      setState(() => _isEditing = false);
      await _fetchProfile(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _logout() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                // Cancel edit: revert
                _nameController.text = _profileData?['full_name'] ?? '';
                _addressController.text = _profileData?['address'] ?? '';
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
          IconButton(
             icon: const Icon(Icons.logout, color: Colors.orangeAccent),
             onPressed: _logout,
             tooltip: 'Logout',
          )
        ],
      ),
      body: _isLoading && _profileData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: Text(
                      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(fontSize: 40, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 48),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: GoogleFonts.outfit(
            color: enabled ? Colors.white : Colors.white60,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: enabled ? Colors.blueAccent : Colors.grey),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: enabled ? BorderSide.none : const BorderSide(color: Colors.transparent),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
