import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import 'pin_screen.dart';

class RechargeScreen extends StatefulWidget {
  final int initialTabIndex;

  const RechargeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _mobileController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedOperator = 'Jio';
  List<String> _operators = [];

  final List<Map<String, dynamic>> _dthOperatorsData = [
    {'name': 'Airtel TV', 'category': 'DTH'},
    {'name': 'Dish TV', 'category': 'DTH'},
    {'name': 'Sun TV', 'category': 'DTH'},
    {'name': 'Tata Sky', 'category': 'DTH'},
    {'name': 'Videocon', 'category': 'DTH'},
    {'name': 'Green Gas Agra', 'category': 'GAS', 'is_default': true},
  ];
  
  // Scheduling
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeOperators();
  }

  void _initializeOperators() {
    if (widget.initialTabIndex == 2) {
      // DTH Only
      _operators = _dthOperatorsData
          .where((e) => e['category'] == 'DTH')
          .map((e) => e['name'] as String)
          .toList();
      _selectedOperator = _operators.isNotEmpty ? _operators.first : 'Airtel TV';
      
    } else if (widget.initialTabIndex == 3) {
      // Gas Only
      _operators = ['Green Gas Agra'];
      _selectedOperator = 'Green Gas Agra';
      
    } else {
      // Mobile
      _operators = ['Jio', 'Airtel', 'Vi', 'BSNL'];
      _selectedOperator = _operators.first;
    }
  }

  @override
  void dispose() {
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



  Future<void> _submitRecharge(bool isScheduled, String category) async {
    if (_mobileController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Mobile Validation
    if (category == 'MOBILE_PREPAID') {
        if (!RegExp(r'^[0-9]{10}$').hasMatch(_mobileController.text)) {
             showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: Text('Invalid Number', style: GoogleFonts.outfit(color: Colors.redAccent)),
                  content: Text('Please enter a valid 10-digit mobile number.', style: GoogleFonts.outfit(color: Colors.white70)),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
             );
             return;
        }
    }

    String? scheduledAt;
    if (isScheduled) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date')));
        return;
      }
      // Default to 10:00 AM
      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        10, // Default Hour
        0,  // Default Minute
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
        category: category,
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

  String _getTitle() {
    switch (widget.initialTabIndex) {
      case 0: return 'Mobile Recharge';
      case 1: return 'Schedule Recharge';
      case 2: return 'DTH Recharge';
      case 3: return 'Green Gas Bill';
      default: return 'Recharge';
    }
  }

  Widget _getBody() {
    switch (widget.initialTabIndex) {
      case 0: return _buildForm(type: 'Mobile', category: 'MOBILE_PREPAID', isScheduled: false, label: 'Mobile Number', icon: Icons.phone_android, isNumeric: true);
      case 1: return _buildForm(type: 'Schedule', category: 'MOBILE_PREPAID', isScheduled: true, label: 'Mobile Number', icon: Icons.phone_android, isNumeric: true);
      case 2: return _buildForm(type: 'DTH Recharge', category: 'DTH', isScheduled: false, label: 'Subscriber ID', icon: Icons.tv, isNumeric: false);
      case 3: return _buildForm(type: 'Green Gas Bill', category: 'GAS', isScheduled: false, label: 'Consumer Number', icon: Icons.gas_meter, isNumeric: false);
      default: return _buildForm(type: 'Mobile', category: 'MOBILE_PREPAID', isScheduled: false, label: 'Mobile Number', icon: Icons.phone_android, isNumeric: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _getBody(),
    );
  }

  Widget _buildForm({
    required String type, 
    required String category, 
    required bool isScheduled,
    required String label,
    required IconData icon,
    required bool isNumeric,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _mobileController,
            label: label,
            icon: icon,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          category == 'GAS' 
            ? _buildStaticOperator('Green Gas Agra') 
            : _buildDropdown(),
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
              ],
            ),
            const SizedBox(height: 32),
          ],
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _submitRecharge(isScheduled, category),
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

  Widget _buildPlaceholder({required String type, required IconData icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Enter details for $type', style: GoogleFonts.outfit(color: Colors.grey)),
          const SizedBox(height: 16),
          // We can reuse the same form structure later or a simplified one
          SizedBox(
            width: 200,
            child: TextField(
               style: GoogleFonts.outfit(color: Colors.white),
               decoration: InputDecoration(
                 hintText: 'Consumer ID / Number',
                 hintStyle: GoogleFonts.outfit(color: Colors.grey),
                 filled: true,
                 fillColor: Colors.white.withOpacity(0.05),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
               ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () { 
                // Generic submit for now
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Sent to Admin')));
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
  Widget _buildStaticOperator(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        name,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
