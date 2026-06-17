import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFFF2F2F2);
  static const Color dark      = Color(0xFF1A1A1A);
  static const Color black     = Color(0xFF000000);
  static const Color gold      = Color(0xFFC9A230);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color grey      = Color(0xFF8A8A8A);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color cardBg    = Color(0xFFFFFFFF);
  static const Color redLight  = Color(0xFFFFEBEB);
  static const Color red       = Color(0xFFE53E3E);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: black,
      secondary: gold,
      surface: white,
    ),
    textTheme: GoogleFonts.montserratTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: black, 
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18, fontWeight: FontWeight.w700, color: white, letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: black,
        foregroundColor: white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      hintStyle: GoogleFonts.montserrat(
        fontSize: 14, color: grey, letterSpacing: 1,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: black, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
  );
}
