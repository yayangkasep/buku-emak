import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    final formatter = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Ringkasan Cuan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: firebaseService.getAllActivities(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final activities = snapshot.data ?? [];
          int totalCommission = activities.fold(0, (sum, item) => sum + item.adminFee);
          int activeGroups = activities.length;

          // Category counts
          Map<String, int> catCounts = {};
          for (var act in activities) {
            catCounts[act.type] = (catCounts[act.type] ?? 0) + 1;
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Komisi Emak', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${formatter.format(totalCommission)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _miniStat(Icons.groups_rounded, '$activeGroups Grup', 'Aktif'),
                          const SizedBox(width: 20),
                          _miniStat(Icons.trending_up_rounded, 'Berjalan', 'Status'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Breakdown Title
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('Rincian Per Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ),
              ),

              // Category Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _categoryStatTile('Arisan', catCounts['arisan'] ?? 0, Colors.green),
                    _categoryStatTile('Tabungan', catCounts['tabungan'] ?? 0, Colors.blue),
                    _categoryStatTile('Tagihan', catCounts['tagihan'] ?? 0, Colors.orange),
                    _categoryStatTile('Paket', catCounts['paket'] ?? 0, Colors.purple),
                  ],
                ),
              ),

              // List of Sources
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 12),
                  child: Text('Sumber Komisi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ),
              ),

              activities.isEmpty 
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Belum ada data komisi.'))))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = activities[index];
                      if (item.adminFee == 0) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _getColor(item.type).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(_getIcon(item.type), color: _getColor(item.type), size: 18),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  Text(item.type.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Text('Rp ${formatter.format(item.adminFee)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                          ],
                        ),
                      );
                    },
                    childCount: activities.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _categoryStatTile(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_getIcon(label.toLowerCase()), color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'arisan': return Icons.groups_rounded;
      case 'tabungan': return Icons.account_balance_wallet_rounded;
      case 'tagihan': return Icons.receipt_long_rounded;
      case 'paket': return Icons.inventory_2_rounded;
      default: return Icons.category_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'arisan': return Colors.green;
      case 'tabungan': return Colors.blue;
      case 'tagihan': return Colors.orange;
      case 'paket': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
