import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgColor = Color(0xFF0B1519);
  static const Color navBgColor = Color(0xFF0F1E24);
  static const Color cardColor = Color(0xFF14252C);
  static const Color accentCyan = Color(0xFF01D1E7);
  static const Color accentPurple = Color(0xFFAC26E7);
  static const Color textGrey = Color(0xFF7D8E96);

  static final ThemeData customDarkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    cardColor: cardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white70),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  static const Color backgroundColor = bgColor;
}