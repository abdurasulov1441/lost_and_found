import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_and_find/home.dart';
import 'package:lost_and_find/pages/adminpanel.dart';
import 'package:lost_and_find/pages/login.dart';

class AuthChecker extends StatelessWidget {
  const AuthChecker({Key? key}) : super(key: key);

  Future<bool> _isAdmin(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admin')
          .doc('admin_email')
          .get();
      if (snapshot.exists) {
        final adminEmail = snapshot['email'];
        return adminEmail == email;
      }
    } catch (e) {
      print('Error checking admin email: $e');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return FutureBuilder<bool>(
        future: _isAdmin(user.email!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            // User is an admin
            return const AdminPanel();
          }

          // User is not an admin
          return const HomePage();
        },
      );
    } else {
      return const LoginPage();
    }
  }
}
