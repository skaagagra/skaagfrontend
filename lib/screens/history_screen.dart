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
    final String type = (tx['transaction_type'] ?? '').toString();
    final String desc = (tx['description'] ?? '').toString().toLowerCase();
    
    if (type == 'TRANSFER_RECEIVED') return Icons.call_received;
    if (type == 'TRANSFER_SENT') return Icons.call_made;
    if (type == 'CREDIT') return Icons.add;
    if (type == 'DEBIT') return Icons.remove;

    // Fallback based on text
    if (desc.contains('recharge') || desc.contains('mobile')) return Icons.phone_android;
    if (desc.contains('dth')) return Icons.tv;
    if (desc.contains('gas')) return Icons.gas_meter;
    if (desc.contains('transfer') || desc.contains('send')) return Icons.send;
    
    return Icons.receipt_long; // Default
  }

  Color _getColorForTransaction(dynamic tx) {
    final String type = (tx['transaction_type'] ?? '').toString();
    if (type == 'CREDIT' || type == 'TRANSFER_RECEIVED') return Colors.greenAccent;
    if (type == 'DEBIT' || type == 'TRANSFER_SENT') return Colors.redAccent;
    return Colors.blueAccent;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
      case 'PROCESSING':
        return Colors.orange;
      case 'FAILED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final String title = tx['description'] ?? 'Transaction';
                    final String amount = '₹${tx['amount'] ?? 0}';
                    final DateTime date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
                    final String status = tx['status'] ?? 'SUCCESS';
                    final String? logoUrl = tx['operator_logo'];
                    final String? opName = tx['operator_name'];

                    final String? targetNumber = tx['target_number'];
                    final String? targetName = tx['target_name'];

                    String displayStatus = status.toUpperCase();
                    if (displayStatus == 'PENDING' || displayStatus == 'PROCESSING') {
                      displayStatus = 'PROCESSING';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: logoUrl != null ? Colors.white : _getColorForTransaction(tx).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.network(
                                    logoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(_getIconForTransaction(tx), color: _getColorForTransaction(tx)),
                                  ),
                                )
                              : Icon(_getIconForTransaction(tx), color: _getColorForTransaction(tx)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opName ?? title,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (targetName != null || targetNumber != null)
                                    Text(
                                      targetName != null ? '$targetName ${targetNumber != null ? "($targetNumber)" : ""}' : (targetNumber ?? ""),
                                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              amount,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _getColorForTransaction(tx),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(date),
                                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  displayStatus,
                                  style: GoogleFonts.outfit(
                                    color: _getStatusColor(status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
