import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/firebase_service.dart';
import '../widgets/shared/history_tile.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedCategory = 'Semua';
  String _selectedTimeRange = 'Hari Ini';

  final List<String> _categories = ['Semua', 'Arisan', 'Tabungan', 'Tagihan', 'Paket'];
  final List<String> _timeRanges = ['Hari Ini', 'Kemarin', 'Minggu Ini', 'Bulan Ini', 'Semua'];

  Map<String, DateTime?> _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedTimeRange) {
      case 'Hari Ini':
        return {
          'start': today,
          'end': today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
        };
      case 'Kemarin':
        final yesterday = today.subtract(const Duration(days: 1));
        return {
          'start': yesterday,
          'end': today.subtract(const Duration(milliseconds: 1)),
        };
      case 'Minggu Ini':
        final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return {
          'start': firstDayOfWeek,
          'end': null,
        };
      case 'Bulan Ini':
        final firstDayOfMonth = DateTime(today.year, today.month, 1);
        return {
          'start': firstDayOfMonth,
          'end': null,
        };
      default:
        return {'start': null, 'end': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _getDateRange();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Buku Besar Global', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded),
                if (_selectedCategory != 'Semua' || _selectedTimeRange != 'Hari Ini')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<MessageModel>>(
        stream: _firebaseService.getGlobalHistory(
          category: _selectedCategory,
          startDate: range['start'],
          endDate: range['end'],
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text('Waduh, ada kendala teknis!', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Pastikan Firestore Index sudah dibuat.\n\nDetail: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => setState(() {}),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
                      ],
                    ),
                    child: Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 24),
                  Text('Belum ada transaksi, Nih.', 
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Coba ganti filter di pojok kanan atas.', 
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return HistoryTile(
                message: log,
                onTap: () => _navigateToActivity(context, log),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(List<String> items, String selected, Function(String) onSelected) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selected == item;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
              selectedColor: const Color(0xFF10B981),
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? const Color(0xFF10B981) : Colors.transparent),
              ),
              showCheckmark: false,
              elevation: 0,
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter Transaksi', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'Semua';
                            _selectedTimeRange = 'Hari Ini';
                          });
                          Navigator.pop(context);
                        }, 
                        child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  ButtonTheme(
                    alignedDropdown: true,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF10B981), size: 18),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      ),
                      items: _categories.map((String value) {
                        IconData categoryIcon;
                        switch(value.toLowerCase()) {
                          case 'arisan': categoryIcon = Icons.groups_rounded; break;
                          case 'tabungan': categoryIcon = Icons.account_balance_wallet_rounded; break;
                          case 'tagihan': categoryIcon = Icons.receipt_long_rounded; break;
                          case 'paket': categoryIcon = Icons.inventory_2_rounded; break;
                          default: categoryIcon = Icons.all_inclusive_rounded;
                        }
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(categoryIcon, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => _selectedCategory = val);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  ButtonTheme(
                    alignedDropdown: true,
                    child: DropdownButtonFormField<String>(
                      value: _selectedTimeRange,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF10B981), size: 18),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      ),
                      items: _timeRanges.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => _selectedTimeRange = val);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Terapkan Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToActivity(BuildContext context, MessageModel message) async {
    if (message.chatId.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mencari grup...'), duration: Duration(milliseconds: 700)),
    );

    try {
      DocumentSnapshot? doc;
      String? foundType = message.activityType;

      // If metadata missing (legacy data), search across all categories
      if (foundType == null) {
        final categories = ['arisan', 'tabungan', 'tagihan', 'paket'];
        for (var cat in categories) {
          var testDoc = await FirebaseFirestore.instance.collection(cat).doc(message.chatId).get();
          if (testDoc.exists) {
            doc = testDoc;
            foundType = cat;
            break;
          }
        }
      } else {
        doc = await FirebaseFirestore.instance.collection(foundType).doc(message.chatId).get();
      }
      
      if (doc != null && doc.exists) {
        final chat = ChatModel.fromFirestore(doc);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grup tidak ditemukan!'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
