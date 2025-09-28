import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF002f6c), // University of Mpumalanga dark blue
        secondary: const Color(0xFFffcc00), // University of Mpumalanga yellow
        tertiary: const Color(0xFF3a913f), // University of Mpumalanga green
        surface: const Color(0xFFF8F9FA),
        error: const Color(0xFFFF5963),
        onPrimary: const Color(0xFFFFFFFF),
        onSecondary: const Color(0xFF000000),
        onTertiary: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF15161E),
        onError: const Color(0xFFFFFFFF),
        outline: const Color(0xFFB0BEC5),
        surfaceVariant: const Color(0xFFE3F2FD),
        onSurfaceVariant: const Color(0xFF002f6c),
      ),
      brightness: Brightness.light,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 57.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF002f6c),
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF002f6c),
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36.0,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF002f6c),
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF002f6c),
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002f6c),
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF002f6c),
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002f6c),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002f6c),
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002f6c),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002f6c),
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002f6c),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002f6c),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF15161E),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF15161E),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF15161E),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002f6c),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF002f6c),
          side: const BorderSide(color: Color(0xFF002f6c)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE3F2FD),
        selectedColor: const Color(0xFF002f6c),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF002f6c),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF4A90E2), // Lighter blue for dark mode
        secondary: const Color(0xFFffcc00), // University of Mpumalanga yellow
        tertiary: const Color(0xFF3a913f), // University of Mpumalanga green
        surface: const Color(0xFF15161E),
        error: const Color(0xFFFF5963),
        onPrimary: const Color(0xFFFFFFFF),
        onSecondary: const Color(0xFF000000),
        onTertiary: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFFE5E7EB),
        onError: const Color(0xFFFFFFFF),
        outline: const Color(0xFF37474F),
        surfaceVariant: const Color(0xFF1E2332),
        onSurfaceVariant: const Color(0xFF4A90E2),
      ),
      brightness: Brightness.dark,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 57.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36.0,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE5E7EB),
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE5E7EB),
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE5E7EB),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE5E7EB),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A90E2),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4A90E2),
          side: const BorderSide(color: Color(0xFF4A90E2)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E2332),
        selectedColor: const Color(0xFF4A90E2),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF4A90E2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );