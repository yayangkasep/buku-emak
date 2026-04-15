import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../services/firebase_service.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'activity_list_screen.dart';
import 'history_screen.dart';
import 'summary_screen.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          const HistoryScreen(), // Tab Riwayat Global
          const SummaryScreen(), // Tab Ringkasan (Cuan)
          const NotificationScreen(), // Tab Notifikasi
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 68,
        width: 68,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: FloatingActionButton(
          onPressed: _showCreateDialog,
          backgroundColor: const Color(0xFF10B981),
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: _buildCategoryGrid(),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF10B981),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20, right: -20,
                child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
              ),
            ],
          ),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Buku Emak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8))),
            Text('Halo, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Ibu Ani'}! 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Profil Emak'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(radius: 40, backgroundColor: Color(0xFF10B981), child: Icon(Icons.person, size: 40, color: Colors.white)),
                      const SizedBox(height: 16),
                      Text(FirebaseAuth.instance.currentUser?.displayName ?? 'Ibu Ani', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                  ],
                ),
              );
            },
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return StreamBuilder<Map<String, int>>(
      stream: _firebaseService.getCategoryCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {'arisan': 0, 'tabungan': 0, 'tagihan': 0, 'paket': 0};
        
        return SliverGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            _categoryCard('Arisan', 'Iuran Rutin', '${counts['arisan']} Catatan', Colors.green, Icons.groups_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityListScreen(category: 'arisan', title: 'Arisan', themeColor: Colors.green)));
            }),
            _categoryCard('Tabungan', 'Simpanan', '${counts['tabungan']} Rekening', Colors.blue, Icons.account_balance_wallet_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityListScreen(category: 'tabungan', title: 'Tabungan', themeColor: Colors.blue)));
            }),
            _categoryCard('Tagihan', 'Pengeluaran', '${counts['tagihan']} Tagihan', Colors.orange, Icons.receipt_long_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityListScreen(category: 'tagihan', title: 'Tagihan', themeColor: Colors.orange)));
            }),
            _categoryCard('Paket', 'Kredit Barang', '${counts['paket']} Paket', Colors.purple, Icons.inventory_2_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityListScreen(category: 'paket', title: 'Paket', themeColor: Colors.purple)));
            }),
          ],
        );
      }
    );
  }

  Widget _categoryCard(String title, String subtitle, String info, Color color, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: -15, top: -15,
                child: Icon(icon, size: 80, color: color.withOpacity(0.04)),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const Spacer(),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                      child: Text(info, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return StreamBuilder<List<ChatModel>>(
      stream: _firebaseService.getAllActivities(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Text('Aduh, ada masalah: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada data, Bu!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('Yuk tambahkan arisan pertama Ibu.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: ChatTile(chat: item, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: item)));
                }),
              );
            },
            childCount: items.length,
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 20,
      height: 70,
      notchMargin: 10.0,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.grid_view_rounded, 'Dashboard', 0),
          _navIcon(Icons.receipt_long_rounded, 'Riwayat', 1),
          const SizedBox(width: 48), // Space for FAB
          _navIcon(Icons.analytics_rounded, 'Ringkasan', 2),
          _navIcon(Icons.notifications_rounded, 'Notifikasi', 3),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF10B981) : Colors.grey[400], size: 26),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? const Color(0xFF10B981) : Colors.grey[400])),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateForm(onCreate: _firebaseService.createActivity),
    );
  }
}

class _CreateForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreate;
  const _CreateForm({required this.onCreate});

  @override
  _CreateFormState createState() => _CreateFormState();
}

class _CreateFormState extends State<_CreateForm> {
  final _groupNameController = TextEditingController();
  final _targetController = TextEditingController();
  final _adminFeeController = TextEditingController();
  final _durationController = TextEditingController();
  final _membersController = TextEditingController();
  
  String _selectedCategory = 'arisan'; // arisan, tabungan, paket
  
  double get _targetAmount {
    String raw = _targetController.text.replaceAll('.', '');
    return double.tryParse(raw) ?? 0;
  }
  int get _duration => int.tryParse(_durationController.text) ?? 1;

  String _calculateResult() {
    if (_targetAmount == 0 || _duration == 0) return 'Input target & durasi...';
    double perMonth = _targetAmount / _duration;
    double perWeek = _targetAmount / (_duration * 4);
    final formatter = NumberFormat('#,###', 'id_ID');
    return '💳 Sebulan: Rp ${formatter.format(perMonth.round())}\n📅 Seminggu: Rp ${formatter.format(perWeek.round())}';
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buat Catatan Baru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const SizedBox(height: 24),
              
              // Category Selector
              Row(
                children: [
                  _categoryChip('arisan', 'Arisan', Icons.groups_rounded),
                  const SizedBox(width: 8),
                  _categoryChip('tabungan', 'Tabungan', Icons.account_balance_wallet_rounded),
                  const SizedBox(width: 8),
                  _categoryChip('paket', 'Paket', Icons.inventory_2_rounded),
                ],
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _groupNameController, 
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFFF1F5F9),
                  hintText: 'Nama Grup / Judul Kegiatan', 
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              
              if (_selectedCategory == 'arisan') ...[
                TextField(
                  controller: _membersController, 
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFF1F5F9),
                    hintText: 'Nama-nama Anggota (pisahkan dengan koma)', 
                    helperText: 'Contoh: Bu Siti, Bu Ani, Bu Euis',
                    prefixIcon: const Icon(Icons.people_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true, fillColor: const Color(0xFFF1F5F9),
                        hintText: 'Target Total Pool (Rp)',
                        prefixIcon: const Icon(Icons.payments_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _adminFeeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: InputDecoration(
                        filled: true, fillColor: const Color(0xFFF1F5F9),
                        hintText: 'Komisi Emak (Rp)',
                        prefixIcon: const Icon(Icons.stars_rounded, color: Colors.orange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFFF1F5F9),
                  hintText: 'Durasi / Tempo (Bulan)',
                  prefixIcon: const Icon(Icons.calendar_month_rounded),
                  suffixText: 'Bulan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF10B981).withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Text(_calculateResult(), style: const TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (_groupNameController.text.isEmpty) return;
                    
                    List<String> memberList = _membersController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    int adminFee = int.tryParse(_adminFeeController.text.replaceAll('.', '')) ?? 0;

                    widget.onCreate({
                      'name': _groupNameController.text,
                      'type': _selectedCategory,
                      'targetAmount': _targetAmount.toInt(),
                      'duration': _duration,
                      'adminFee': adminFee,
                      'members': memberList,
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastMessage': 'Baru dibuat',
                      'totalPool': 0,
                      'paidCount': 0,
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8, shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                  ),
                  child: const Text('Simpan & Mulai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String value, String label, IconData icon) {
    bool isSelected = _selectedCategory == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    final formatter = NumberFormat('#,###', 'id_ID');
    String baseText = newValue.text.replaceAll('.', '');
    if (baseText.isEmpty) return newValue.copyWith(text: '');
    int value = int.parse(baseText);
    String newText = formatter.format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
