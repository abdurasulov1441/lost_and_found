import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:lost_and_find/pages/chat_detail.dart';

class FoundItemsPage extends StatefulWidget {
  const FoundItemsPage({super.key});

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
                      }),
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
                      }),
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

                // Apply filters if needed
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
                    final isOwnListing = item['email'] == currentUserEmail;

                    return _buildItemCard(context, item, isOwnListing);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemCard(
      BuildContext context, QueryDocumentSnapshot item, bool isOwnListing) {
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
      onTap: isOwnListing
          ? null // Disable tap for own listings
          : () async {
              final chatId = await _createOrGetChat(
                FirebaseAuth.instance.currentUser!.email!,
                item['email'],
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(
                    chatId: chatId,
                    otherUserEmail: item['email'],
                  ),
                ),
              );
            },
      child: Card(
        color: isOwnListing ? Colors.blue.shade50 : Colors.white,
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
                height: 250, // Fixed height for the image area
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
                        fit: BoxFit
                            .contain, // Ensures the whole image is visible
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
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
                    'ID: ${item['id'] ?? 'Нет ID'}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['name'] ?? 'Название отсутствует',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        'Категория: ${item['category'] ?? 'Не указана'}',
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
                        'Награда: ${item['reward'] ?? 'Не указана'}',
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
                        'Регион: ${item['region'] ?? 'Не указан'}',
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
                      const Icon(Icons.home, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        'Адрес: ${item['address'] ?? 'Не указан'}',
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
                        'Дата: ${item['date'] ?? 'Не указана'}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
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

    final querySnapshot = await chatCollection
        .where('users', arrayContains: currentUserEmail)
        .get();

    for (var doc in querySnapshot.docs) {
      if ((doc['users'] as List).contains(otherUserEmail)) {
        return doc.id;
      }
    }

    final newChat = await chatCollection.add({
      'users': [currentUserEmail, otherUserEmail],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }
}
