import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addCategories() async {
  final List<String> categories = [
    'Kitoblar - O‘yinlar',
    'Velosipedlar - Mashinalar - Texnikalar',
    'Kiyimlar - Taqinchoqlar',
    'Kompyuterlar va Elektronika',
    'Fitness - Sport jihozlari',
    'ID - Hamyonlar - Kalitlar',
    'Yo‘qolgan odamlar - Topilgan hayvonlar',
    'Sayohat - Savat va sumkalar',
  ];

  try {
    final firestore = FirebaseFirestore.instance;

    for (String category in categories) {
      await firestore.collection('categories').add({
        'name': category,
      });
    }

    print('Barcha kategoriyalar muvaffaqiyatli qo‘shildi!');
  } catch (e) {
    print('Kategoriyalarni qo‘shishda xatolik: $e');
  }
}
