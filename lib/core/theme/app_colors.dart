import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  const AppColors._();

  // Base Colors
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF101010);
  static const Color surfaceLight = Color(0xFF1A1A1A);

  // Accent Colors
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70; // or withOpacity(0.7)
  static const Color textDisabled = Colors.white38; // or withOpacity(0.5)

  // Ticket Colors
  static const Color ticketRed = Color(0xFF8B0000);
  static const Color ticketBlue = Color(0xFF00008B);
  static const Color ticketWhite = Color(0xFFF5F5F5);
}
