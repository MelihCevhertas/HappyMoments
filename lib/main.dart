import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:happy_moments/screens/admin_panel.dart';
import 'package:happy_moments/screens/user_upload_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Düğün Kutusu',
      debugShowCheckedModeBanner: false,
      home: UploadScreen(),
      routes: {
        '/admin': (context) => AdminPanel(),
      },
    );
  }
}