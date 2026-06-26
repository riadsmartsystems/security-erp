import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RiadApp());
}

class RiadApp extends StatelessWidget {
  const RiadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIAD Security',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('RIAD Security ERP'),
        ),
      ),
    );
  }
}
