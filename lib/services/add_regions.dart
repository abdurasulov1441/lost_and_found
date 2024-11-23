import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addRegions() async {
  final List<String> regions = [
    'Toshkent',
    'Samarqand',
    'Buxoro',
    'Xorazm',
    'Qashqadaryo',
    'Farg‘ona',
    'Andijon',
    'Namangan',
    'Surxondaryo',
    'Jizzax',
    'Sirdaryo',
    'Navoiy',
    'Qoraqalpog‘iston R',
  ];

  try {
    final firestore = FirebaseFirestore.instance;
    for (String region in regions) {
      await firestore.collection('regions').add({
        'name': region,
      });
    }
    print('Barcha regionlar muvaffaqiyatli qo‘shildi.');
  } catch (e) {
    print('Xatolik yuz berdi: $e');
  }
}
