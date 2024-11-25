import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LostItem extends StatefulWidget {
  const LostItem({super.key});

  @override
  State<LostItem> createState() => _LostItemState();
}

class _LostItemState extends State<LostItem> {
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
        title: const Text('Yo‘qotilgan narsalar'),
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
                  .collection('lostitems')
                  .where('status', isEqualTo: 'active')
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
                      'Yo‘qotilgan narsalar yo‘q',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                final currentUserEmail =
                    FirebaseAuth.instance.currentUser?.email;
                var items = snapshot.data!.docs;

                // Apply filters
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
                    final isOwnListing = currentUserEmail == item['email'];
                    return _buildItemCard(context, item, isOwnListing);
                  },
                );
              },
            ),
          ),
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

    return Card(
      color: isOwnListing ? Colors.green.shade100 : Colors.white,
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
              height:
                  200, // Задаем фиксированную высоту для области отображения
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
                      fit: BoxFit.contain, // Изменяем на BoxFit.contain
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
                      'Narxi: ${item['reward'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      item['region'] ?? 'Joylashuv mavjud emas',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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
    );
  }
}
