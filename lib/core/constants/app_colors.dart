import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryColor = Color(0xFF075E54);
  static const Color accentColor = Color(0xFF128C7E);

  // Scaffold & Backgrounds
  static const Color scaffoldBackgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color chatBackground = Color(0xFFECE5DD);

  // Message Bubbles - UPDATED WITH PROPER NAMES
  static const Color senderMessage = Color(0xFFDCF8C6);  // Light green
  static const Color receiverMessage = Color(0xFFFFFFFF); // White

  // Added new message bubble colors for better distinction
  static const Color myMessageBubble = Color(0xFFDCF8C6);    // WhatsApp green
  static const Color otherMessageBubble = Color(0xFFFFFFFF); // White

  // Alternative message bubble colors
  static const Color messageBubble = Color(0xFFEDEDED);       // Grey bubble
  static const Color messageBubbleSent = Color(0xFFDCF8C6);   // Sent message
  static const Color messageBubbleReceived = Color(0xFFFFFFFF); // Received message

  // Text & UI Elements
  static const Color textColor = Color(0xFF000000);
  static const Color subtitleColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFBDBDBD);
  static const Color onlineIndicator = Color(0xFF4CAF50);

  // Status Colors
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA000);

  // Icons
  static const Color iconColor = Color(0xFF075E54);
  static const Color iconDisabled = Color(0xFFBDBDBD);

  // Buttons
  static const Color buttonColor = Color(0xFF128C7E);
  static const Color buttonTextColor = Color(0xFFFFFFFF);
  static const Color buttonDisabled = Color(0xFFBDBDBD);

  // Input Fields
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputHint = Color(0xFF9E9E9E);

  // Status Indicators
  static const Color typingIndicator = Color(0xFF4CAF50);
  static const Color offlineIndicator = Color(0xFF757575);
  static const Color awayIndicator = Color(0xFFFF9800);

  // Message Status Colors
  static const Color messageSent = Color(0xFF666666);
  static const Color messageDelivered = Color(0xFF666666);
  static const Color messageRead = Color(0xFF4FC3F7);

  // Time Stamps
  static const Color timestamp = Color(0xFF666666);
  static const Color timestampDark = Color(0xFFFFFFFF);

  // Shadows
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
}
