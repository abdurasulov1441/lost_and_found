import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lost_and_find/services/auth_cheker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lost_and_find/services/notification.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
