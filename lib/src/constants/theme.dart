import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primarySeedColor = Colors.green;
const Color lightGreen = Color(0xFFC8E6C9); // Colors.green[100]
const Color mediumGreen = Color(0xFF66BB6A); // Colors.green[400]
const Color richBlack = Color(0xFF000000);
const Color darkGreen = Color(0xFF006400); // Dark Green

final TextTheme appTextTheme = TextTheme(
  displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
  titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
  bodyMedium: GoogleFonts.openSans(fontSize: 14),
);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySeedColor,
    brightness: Brightness.light,
  ),
  textTheme: appTextTheme,
  appBarTheme: AppBarTheme(
    backgroundColor: mediumGreen, // Updated header color
    foregroundColor: Colors.white,
    titleTextStyle: GoogleFonts.oswald(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: lightGreen, // Keep light green for buttons
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: darkGreen,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
  ),
  cardColor: lightGreen, // Set card color for consistency
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySeedColor,
    brightness: Brightness.dark,
  ),
  textTheme: appTextTheme,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900],
    foregroundColor: Colors.white,
    titleTextStyle: GoogleFonts.oswald(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.green.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.grey[900],
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
  ),
);
