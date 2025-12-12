import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final data = await ApiService().getTransactions();
      if (mounted) {
        setState(() {
          _transactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIconForTransaction(dynamic tx) {
    // Logic to determine icon based on 'type' or description fallback
    // Assuming 'type' field exists or we check description text
    final String desc = (tx['description'] ?? '').toString().toLowerCase();
    
    if (desc.contains('recharge') || desc.contains('mobile')) return Icons.phone_android;
    if (desc.contains('dth')) return Icons.tv;
    if (desc.contains('gas')) return Icons.gas_meter;
    if (desc.contains('transfer') || desc.contains('send')) return Icons.send;
    if (desc.contains('wallet') || desc.contains('topup') || desc.contains('add')) return Icons.account_balance_wallet;
    
    return Icons.receipt_long; // Default
  }

  Color _getColorForTransaction(dynamic tx) {
      final String desc = (tx['description'] ?? '').toString().toLowerCase();
       if (desc.contains('failed')) return Colors.redAccent;
       return Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(child: Text('No transactions found', style: GoogleFonts.outfit(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final String title = tx['description'] ?? 'Transaction';
                    final String amount = '₹ ${tx['amount'] ?? 0}';
                    final DateTime date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
                    
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForTransaction(tx).withOpacity(0.1),
                          child: Icon(_getIconForTransaction(tx), color: _getColorForTransaction(tx)),
                        ),
                        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(DateFormat.yMMMd().add_jm().format(date), style: GoogleFonts.outfit(color: Colors.grey)),
                        trailing: Text(amount, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    );
                  },
                ),
    );
  }
}
