import 'package:flutter/material.dart';
import 'package:rairepo/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Live Report',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37), // Gold
          surface: Color(0xFF101010),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default, but can be customized
      ),
      routerConfig: router,
    );
  }
}
