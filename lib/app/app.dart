
import 'package:flutter/material.dart';

class LittleByLittleApp extends StatelessWidget {
  const LittleByLittleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Little by Little',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Little by Little'),
        ),
      ),
    );
  }
}
