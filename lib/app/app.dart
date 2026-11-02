
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class LittleByLittleApp extends StatelessWidget {
  const LittleByLittleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Little by Little',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Text('Little by Little'),
        ),
      ),
    );
  }
}
