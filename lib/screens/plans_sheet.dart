import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recharge_plan.dart';
import '../services/api_service.dart';

class PlansSheet extends StatefulWidget {
  final int operatorId;
  final String operatorName;
  final String circle;

  const PlansSheet({
    Key? key,
    required this.operatorId,
    required this.operatorName,
    this.circle = 'ALL',
  }) : super(key: key);

  @override
  _PlansSheetState createState() => _PlansSheetState();
}

class _PlansSheetState extends State<PlansSheet> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<RechargePlan> _plans = [];
  bool _isLoading = true;
  late TabController _tabController;
  final List<String> _tabs = ['UNLIMITED', 'DATA', 'OTHER', 'TOPUP', 'SMS', 'ROAMING'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await _apiService.getPlans(operatorId: widget.operatorId, circle: widget.circle);
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<RechargePlan> _getPlansByType(String type) {
    return _plans.where((p) => p.planType == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Browse Plans - ${widget.operatorName}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _tabs.map((type) {
                      final plans = _getPlansByType(type);
                      if (plans.isEmpty) return Center(child: Text('No plans found', style: GoogleFonts.outfit(color: Colors.grey)));
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return Card(
                            color: Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => Navigator.pop(context, plan),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('₹${double.parse(plan.amount).toInt()}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                          child: Text(plan.validity, style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(plan.data, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                                    if (plan.additionalBenefits.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(plan.additionalBenefits, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
