import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FoundItemsPage extends StatefulWidget {
  const FoundItemsPage({super.key});

  @override
  _FoundItemsPageState createState() => _FoundItemsPageState();
}

class _FoundItemsPageState extends State<FoundItemsPage> {
  Future<void> _deleteItem(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('found')
          .doc(documentId)
          .delete();

      if (!mounted) return; // Проверяем, что виджет ещё активен
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E’lon muvaffaqiyatli o‘chirildi')),
      );
    } catch (e) {
      debugPrint('Failed to delete item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topilgan narsalar'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('found')
            .where('email', isEqualTo: userEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Siz hali topilgan narsalar qo‘shmadingiz',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final items = snapshot.data!.docs;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, QueryDocumentSnapshot item) {
    List<String> images = [];
    if (item['images'] != null) {
      images = List<String>.from(item['images'].map((image) {
        try {
          final decoded = jsonDecode(image);
          return decoded['path'] ?? '';
        } catch (e) {
          return image.toString();
        }
      }));
    }

    // Проверяем наличие полей reward и address
    final Map<String, dynamic> data = item.data() as Map<String, dynamic>;
    final reward = data.containsKey('reward') ? data['reward'] : 'N/A';
    final address = data.containsKey('address') ? data['address'] : 'N/A';

    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageUrl = 'https://appdata.uz${images[index]}';
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Nomi mavjud emas',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.category, 'Kategoriya', item['category']),
                _buildDetailRow(Icons.money_rounded, 'Mukofot', reward),
                _buildDetailRow(Icons.location_on, 'Joylashuv', item['region']),
                _buildDetailRow(Icons.home, 'Manzil', address),
                _buildDetailRow(Icons.calendar_today, 'Sana', item['date']),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final confirmation = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('O‘chirishni tasdiqlang'),
                        content:
                            const Text('Ushbu e’loni o‘chirishni xohlaysizmi?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Bekor qilish'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('O‘chirish'),
                          ),
                        ],
                      ),
                    );

                    if (confirmation == true) {
                      if (!mounted) return;
                      await _deleteItem(item.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'O‘chirish',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ${value ?? 'Ma’lumot mavjud emas'}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
