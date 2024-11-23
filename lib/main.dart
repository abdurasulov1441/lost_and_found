import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lost_and_find/services/auth_cheker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lost and Find',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const AuthChecker(),
    );
  }
}
