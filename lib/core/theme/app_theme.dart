import 'package:flutter/material.dart';

class AppTheme {
  static const Color felt = Color(0xFF1B5E3A);
  static const Color feltDark = Color(0xFF123D26);
  static const Color gold = Color(0xFFD4AF37);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: felt,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: feltDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: feltDark,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
}
