import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:lost_and_find/pages/chat_detail.dart';

class FoundItemsPage extends StatefulWidget {
  const FoundItemsPage({Key? key}) : super(key: key);

  @override
  State<FoundItemsPage> createState() => _FoundItemsPageState();
}

class _FoundItemsPageState extends State<FoundItemsPage> {
  bool showFilters = false;
  String? selectedCategory;
  String? selectedRegion;
  String? selectedDate;
  List<String> categories = [];
  List<String> regions = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchRegions();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchRegions() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('regions').get();
      setState(() {
        regions = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Error fetching regions: $e');
    }
  }

  void _clearFilters() {
    setState(() {
      selectedCategory = null;
      selectedRegion = null;
      selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topilgan narsalar'),
        leading: IconButton(
          icon: Icon(showFilters ? Icons.filter_alt_off : Icons.filter_alt),
          onPressed: () {
            setState(() {
              showFilters = !showFilters;
            });
          },
        ),
        actions: [
          if (showFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          if (showFilters)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategoriya',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Barcha kategoriyalar'),
                      ),
                      ...categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRegion,
                    decoration: const InputDecoration(
                      labelText: 'Joylashuv',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Barcha joylashuvlar'),
                      ),
                      ...regions.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRegion = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate =
                              "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Sana',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedDate ?? 'Barcha sanalar',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('found')
                  .where('status',
                      isEqualTo: 'active') // Only fetch active items
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Topilgan narsalar yo‘q',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final currentUserEmail =
                    FirebaseAuth.instance.currentUser?.email;
                var items = snapshot.data!.docs;

                // Exclude items that belong to the current user
                items = items.where((item) {
                  return item['email'] != currentUserEmail;
                }).toList();

                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sizning e\'lonlaringizdan boshqa e\'lonlar mavjud emas',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                // Apply additional filters if needed
                if (selectedCategory != null) {
                  items = items.where((item) {
                    return item['category'] == selectedCategory;
                  }).toList();
                }

                if (selectedRegion != null) {
                  items = items.where((item) {
                    return item['region'] == selectedRegion;
                  }).toList();
                }

                if (selectedDate != null) {
                  items = items.where((item) {
                    return item['date'] == selectedDate;
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemCard(context, item);
                  },
                );
              },
            ),
          )
        ],
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

    return GestureDetector(
      onTap: () async {
        final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
        final itemUserEmail = item['email'];

        if (currentUserEmail == null || itemUserEmail == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при открытии чата')),
          );
          return;
        }

        // Create or get chat
        final chatId = await _createOrGetChat(currentUserEmail, itemUserEmail);

        // Navigate to chat detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              chatId: chatId,
              otherUserEmail: itemUserEmail,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        margin: const EdgeInsets.only(bottom: 16.0),
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
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey, size: 50),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Nomi mavjud emas',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.numbers, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        'ID: ${item['id'] ?? 'ID mavjud emas'}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        'Mukofot: ${item['reward'] ?? 'Mukofot mavjud emas'}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        item['date'] ?? 'Sana mavjud emas',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        item['category'] ?? 'Kategoriya mavjud emas',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        item['region'] ?? 'Joylashuv mavjud emas',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (item['address'] != null)
                    Row(
                      children: [
                        const Icon(Icons.home, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            item['address'],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _createOrGetChat(
      String currentUserEmail, String otherUserEmail) async {
    final chatCollection = FirebaseFirestore.instance.collection('chats');

    try {
      // Поиск существующего чата
      final querySnapshot = await chatCollection
          .where('users', arrayContains: currentUserEmail)
          .get();

      // Проверка на наличие документов
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final users = doc['users'] as List;
          if (users.contains(otherUserEmail)) {
            return doc.id; // Возвращаем id существующего чата
          }
        }
      }

      // Если чат не найден, создаем новый
      final newChat = await chatCollection.add({
        'users': [currentUserEmail, otherUserEmail],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newChat.id; // Возвращаем id нового чата
    } catch (e) {
      print('Ошибка при создании или поиске чата: $e');
      throw Exception('Не удалось создать или найти чат');
    }
  }
}
