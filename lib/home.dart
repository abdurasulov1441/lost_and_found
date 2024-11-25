import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_and_find/pages/account.dart';
import 'package:lost_and_find/pages/add_item.dart';
import 'package:lost_and_find/pages/login.dart';
import 'package:lost_and_find/pages/lost_item.dart';
import 'package:lost_and_find/pages/found_items.dart';
import 'package:lost_and_find/pages/chat.dart';
import 'package:lost_and_find/services/custom_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FoundItemsPage(),
    LostItem(),
    ChatPage(),
    AccountPage(),
  ];

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    } catch (e) {
      print('Xatolik: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tizimdan chiqishda xatolik')),
      );
    }
  }

  void _onFabPressed() {
    // Обработка нажатия на FAB
    if (_currentIndex == 0 || _currentIndex == 1) {
      // Переход на страницу добавления найденных вещей
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddItemSelectionPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Bu funksiya faqat Topilgan yoki Yo‘qotilgan bo‘limida mavjud')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'L&F UZB',
        showLogoutButton: true,
        onLogout: _logout,
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        heroTag: 'uniqueTag',
        onPressed: _onFabPressed,
        backgroundColor: const Color.fromARGB(255, 19, 195, 169),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 19, 195, 169),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Topilgan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cancel),
            label: 'Yo\'qotilgan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Akkount',
          ),
        ],
      ),
    );
  }
}
