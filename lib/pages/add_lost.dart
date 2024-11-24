import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AddLostPage extends StatefulWidget {
  const AddLostPage({Key? key}) : super(key: key);

  @override
  State<AddLostPage> createState() => _AddLostPageState();
}

class _AddLostPageState extends State<AddLostPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedRegion;
  List<String> _regions = [];
  List<String> _categories = [];
  final List<File?> _images = [null, null, null];

  bool _showPriceField = false; // Toggle for price input field

  @override
  void initState() {
    super.initState();
    _fetchRegions();
    _fetchCategories();
  }

  Future<void> _fetchRegions() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('regions').get();
      setState(() {
        _regions = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Joylashuvlarni olishda xatolik: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Kategoriyalarni olishda xatolik: $e');
    }
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _images[index] = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate() &&
        _selectedCategory != null &&
        _selectedRegion != null) {
      try {
        // Get the current user
        final user = FirebaseAuth.instance.currentUser;
        final userEmail = user?.email ?? 'No email';

        // Upload images to the server
        List<String> uploadedImageUrls = [];
        for (var image in _images) {
          if (image != null) {
            String? imageUrl = await _uploadImageToServer(image);
            if (imageUrl != null) {
              uploadedImageUrls.add(imageUrl);
            }
          }
        }

        // Retrieve and increment the sequential id from the 'numbers' collection
        final numberDoc = FirebaseFirestore.instance
            .collection('numbers')
            .doc('lostitems_count');
        final numberSnapshot = await numberDoc.get();

        int currentId = 1; // Default to 1 if the document doesn't exist
        if (numberSnapshot.exists && numberSnapshot.data() != null) {
          currentId = numberSnapshot.data()!['current'] ?? 1;
        }

        // Increment the sequence in Firestore
        await numberDoc.set({'current': currentId + 1});

        // Save data to Firestore with status and id
        await FirebaseFirestore.instance.collection('lostitems').add({
          'name': _nameController.text,
          'date': _dateController.text,
          'category': _selectedCategory,
          'region': _selectedRegion,
          'address': _addressController.text,
          'images': uploadedImageUrls,
          'email': userEmail,
          'createdAt': Timestamp.now(),
          'id': currentId, // Sequential id
          'status': 'inactive', // Default status
          if (_showPriceField) 'price': _priceController.text, // Optional price
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ma’lumot saqlandi!')),
        );

        Navigator.pop(context);
      } catch (e) {
        print('Ma’lumotni saqlashda xatolik: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xatolik yuz berdi!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcha maydonlarni to‘ldiring!')),
      );
    }
  }

  Future<String?> _uploadImageToServer(File image) async {
    try {
      final uri = Uri.parse('https://appdata.uz/upload.php');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Image uploaded: $responseBody');
        return responseBody;
      } else {
        print('Image upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Xatolik suratni yuklashda: $e');
    }
    return null;
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kategoriyani tanlang',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 20.0),
                        decoration: BoxDecoration(
                          color: _selectedCategory == category
                              ? const Color.fromARGB(255, 19, 195, 169)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _selectedCategory == category
                                ? const Color.fromARGB(255, 19, 195, 169)
                                : Colors.grey,
                          ),
                        ),
                        child: Text(
                          category,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: _selectedCategory == category
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yo‘qolgan narsani qo‘shish',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 19, 195, 169),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Narsaning nomi'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Narsaning nomini kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dateController,
                decoration: _inputDecoration('Yo‘qolgan sana').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dateController.text =
                              "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                        });
                      }
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yo‘qolgan sanani kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showCategoryBottomSheet,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    _selectedCategory ?? 'Kategoriyani tanlang',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Joylashuv',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                items: _regions
                    .map((region) => DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                  });
                },
                decoration: _inputDecoration('Joylashuvni tanlang'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Manzilni kiriting'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Manzilni kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Narxni kiritish (ixtiyoriy)',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
              ),
              SwitchListTile(
                title: const Text('Narx qo‘shish'),
                value: _showPriceField,
                onChanged: (value) {
                  setState(() {
                    _showPriceField = value;
                  });
                },
              ),
              if (_showPriceField)
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Narxni kiriting'),
                ),
              const SizedBox(height: 20),
              const Text(
                'Rasmlarni qo‘shish',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  return GestureDetector(
                    onTap: () => _pickImage(index),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                        image: _images[index] != null
                            ? DecorationImage(
                                image: FileImage(_images[index]!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _images[index] == null
                          ? const Icon(Icons.add_a_photo, color: Colors.grey)
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 19, 195, 169),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Center(
                  child: Text(
                    'Ma’lumotni saqlash',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      filled: true,
      fillColor: Colors.grey.shade200,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Colors.grey,
      ),
    );
  }
}
