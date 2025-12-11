import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import 'pin_screen.dart';

class RechargeScreen extends StatefulWidget {
  final bool initialModeScheduled;

  const RechargeScreen({super.key, this.initialModeScheduled = false});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> with SingleTickerProviderStateMixin {
  final _mobileController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedOperator = 'Jio';
  final List<String> _operators = ['Jio', 'Airtel', 'Vi', 'BSNL'];
  
  late TabController _tabController;
  
  // Scheduling
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialModeScheduled ? 1 : 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitRecharge(bool isScheduled) async {
    if (_mobileController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    String? scheduledAt;
    if (isScheduled) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time')));
        return;
      }
      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      scheduledAt = dt.toIso8601String();
    }

    // Verify PIN or Biometric before submission
    bool isVerified = false;
    final bioService = BiometricService();
    
    if (await bioService.isDeviceSupported()) {
      isVerified = await bioService.authenticate(reason: 'Authenticate to complete recharge');
    }

    if (!isVerified) {
       final bool? pinVerified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PinScreen(mode: PinMode.verify),
          fullscreenDialog: true,
        ),
      );
      isVerified = pinVerified ?? false;
    }

    if (!isVerified) return; // Verification failed or cancelled

    setState(() => _isLoading = true);
    try {
      await ApiService().submitRecharge(
        mobileNumber: _mobileController.text,
        operator: _selectedOperator,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        isScheduled: isScheduled,
        scheduledAt: scheduledAt,
      );
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Success', style: GoogleFonts.outfit(color: Colors.white)),
          content: Text(
            isScheduled ? 'Recharge Scheduled Successfully!' : 'Recharge Request Submitted!',
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // Screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recharge Mobile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Recharge Now'),
            Tab(text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm(isScheduled: false),
          _buildForm(isScheduled: true),
        ],
      ),
    );
  }

  Widget _buildForm({required bool isScheduled}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _mobileController,
            label: 'Mobile Number',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildDropdown(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'Amount (₹)',
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          if (isScheduled) ...[
            Text('Schedule Date & Time', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null ? 'Select Date' : DateFormat.yMMMd().format(_selectedDate!),
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _submitRecharge(isScheduled),
              style: ElevatedButton.styleFrom(
                backgroundColor: isScheduled ? Colors.purpleAccent : Colors.orangeAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isScheduled ? 'Schedule Recharge' : 'Recharge Now',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedOperator,
          dropdownColor: const Color(0xFF1E293B),
          style: GoogleFonts.outfit(color: Colors.white),
          isExpanded: true,
          items: _operators.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedOperator = newValue!;
            });
          },
        ),
      ),
    );
  }
}
