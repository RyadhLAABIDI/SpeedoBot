import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';

final  appTheme = ThemeData(
  //fontFamily: GoogleFonts.outfit().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    secondary: Colors.amber,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  ),
);
