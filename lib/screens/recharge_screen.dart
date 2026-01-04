import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/operator.dart';
import '../models/recharge_plan.dart';
import 'plans_sheet.dart';
import '../widgets/success_animation.dart';

class RechargeScreen extends StatefulWidget {
  final int initialTabIndex;

  const RechargeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _mobileController = TextEditingController();
  final _amountController = TextEditingController();
  
  Operator? _selectedOperator;
  List<Operator> _operators = [];
  bool _isLoadingOperators = true;
  bool _isPrepaid = true;
  bool _isScheduled = false;
  DateTime? _selectedDate;
  bool _isLoading = false;

  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex == 1 ? 0 : widget.initialTabIndex;
    _isScheduled = widget.initialTabIndex == 1;
    _amountController.addListener(() => setState(() {}));
    _fetchOperators();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    setState(() => _isLoadingOperators = true);
    try {
      String? category;
      if (_currentTabIndex == 2) category = 'DTH';
      else if (_currentTabIndex == 3) category = 'GAS';
      else category = _isPrepaid ? 'MOBILE_PREPAID' : 'MOBILE_POSTPAID';

      final ops = await ApiService().getOperators(category: category);
      setState(() {
        _operators = ops;
        if (_operators.isNotEmpty) {
          try {
            _selectedOperator = _operators.firstWhere((op) => op.isDefault);
          } catch (_) {
            _selectedOperator = _operators.first;
          }
        } else {
          _selectedOperator = null;
        }
        _isLoadingOperators = false;
      });
    } catch (e) {
      debugPrint('Error fetching operators: $e');
      setState(() => _isLoadingOperators = false);
    }
  }
  
  void _openPlansSheet() async {
    if (_selectedOperator == null) return;
    
    final RechargePlan? selectedPlan = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlansSheet(
        operatorId: _selectedOperator!.id, 
        operatorName: _selectedOperator!.name,
      ),
    );

    if (selectedPlan != null) {
      setState(() {
        _amountController.text = double.parse(selectedPlan.amount).toInt().toString();
      });
    }
  }

  Future<void> _submitRecharge() async {
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an operator')));
      return;
    }

    if (_mobileController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    String category;
    if (_currentTabIndex == 2) category = 'DTH';
    else if (_currentTabIndex == 3) category = 'GAS';
    else category = _isPrepaid ? 'MOBILE_PREPAID' : 'MOBILE_POSTPAID';

    if ((category == 'MOBILE_PREPAID' || category == 'MOBILE_POSTPAID') && 
        !RegExp(r'^[0-9]{10}$').hasMatch(_mobileController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Mobile Number')));
      return;
    }

    String? scheduledAt;
    if (_isScheduled) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date')));
        return;
      }
      final dt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 10, 0);
      scheduledAt = dt.toIso8601String();
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().submitRecharge(
        mobileNumber: _mobileController.text,
        operator: _selectedOperator!.name,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        category: category,
        isScheduled: _isScheduled,
        scheduledAt: scheduledAt,
      );
      
      if (!mounted) return;

      // Show Success Animation
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => SuccessAnimation(
            message: 'Dear customer, your request has been successfully submitted.',
            onFinished: () {
              Navigator.of(context).pop(); // Back to Home
            },
          ),
        ),
      );

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(_getTitle(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildForm(),
    );
  }
  
  String _getTitle() {
    switch (_currentTabIndex) {
      case 0: return 'Mobile Recharge';
      case 2: return 'DTH Recharge';
      case 3: return 'Green Gas Bill';
      default: return 'Recharge';
    }
  }

  Widget _buildForm() {
    if (_isLoadingOperators) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

    String label = 'Mobile Number';
    IconData icon = Icons.phone_android;
    bool isNumeric = true;
    String category = _isPrepaid ? 'MOBILE_PREPAID' : 'MOBILE_POSTPAID';

    if (_currentTabIndex == 2) {
      label = 'Subscriber ID';
      icon = Icons.tv;
      isNumeric = false;
      category = 'DTH';
    } else if (_currentTabIndex == 3) {
      label = 'Consumer Number';
      icon = Icons.gas_meter;
      isNumeric = false;
      category = 'GAS';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_currentTabIndex == 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTypeToggle(title: 'Prepaid', isSelected: _isPrepaid, onTap: () {
                    setState(() { _isPrepaid = true; });
                    _fetchOperators();
                  })),
                  Expanded(child: _buildTypeToggle(title: 'Postpaid', isSelected: !_isPrepaid, onTap: () {
                    setState(() { _isPrepaid = false; });
                    _fetchOperators();
                  })),
                ],
              ),
            ),
          ],
          
          _buildTextField(
            controller: _mobileController, 
            label: label, 
            icon: icon, 
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text
          ),
          const SizedBox(height: 16),
          _buildOperatorDropdown(),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _amountController, 
                  label: 'Amount (₹)', 
                  icon: Icons.currency_rupee, 
                  keyboardType: TextInputType.number
                )
              ),
              if (category == 'MOBILE_PREPAID') ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: TextButton(
                    onPressed: _openPlansSheet,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text('Plans', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                )
              ]
            ],
          ),
          
          if (category != 'MOBILE_PREPAID') ...[
            const SizedBox(height: 16),
            _buildFeeBreakdown(category),
          ],
          
          const SizedBox(height: 12),
          
          // Scheduling Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Checkbox(
                  value: _isScheduled,
                  onChanged: (val) => setState(() => _isScheduled = val ?? false),
                  activeColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Text(
                  'Schedule for later',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          if (_isScheduled) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null ? 'Select Scheduling Date' : DateFormat('dd MMMM, yyyy').format(_selectedDate!),
                      style: GoogleFonts.outfit(color: _selectedDate == null ? Colors.white38 : Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRecharge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text('Continue', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }

  Widget _buildOperatorDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Operator>(
          value: _selectedOperator,
          dropdownColor: const Color(0xFF1E293B),
          style: GoogleFonts.outfit(color: Colors.white),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          hint: Text('Select Operator', style: GoogleFonts.outfit(color: Colors.white38)),
          items: _operators.map((op) => DropdownMenuItem(
            value: op, 
            child: Text(op.name, style: GoogleFonts.outfit()),
          )).toList(),
          onChanged: (val) => setState(() => _selectedOperator = val),
        ),
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _buildTypeToggle({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : Colors.white38, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
      ),
    );
  }
  
  Widget _buildFeeBreakdown(String category) {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return const SizedBox.shrink();

    double fee = amount * 0.03;
    double total = amount + fee;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Base Amount', style: GoogleFonts.outfit(color: Colors.white70)),
            Text('₹${amount.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Platform Fee (3%)', style: GoogleFonts.outfit(color: Colors.white70)),
            Text('+ ₹${fee.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.orangeAccent)),
          ]),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Payable', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('₹${total.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 20)),
          ]),
        ],
      ),
    );
  }
}
