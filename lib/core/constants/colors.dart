import 'package:flutter/material.dart';

final List<Color> topStreakColors = [
  Colors.green.shade400,
  Colors.green.shade300,
  Colors.green.shade200,
];

class AppColors {
  static const kDefaultTextColor = Colors.black;

  static const kRemainingTextColor = Colors.green;
  static const kOverdueTextColor = Colors.red;

  static const kActiveTextColor = Color(0xFF40BB4D);
  static const kDeactivateTextColor = Color(0xFFC4C4C4);

  static const kLevel3Color = Colors.red; // Do It Now - Important & Urgent
  static const kLevel2Color = Colors.green; // Schedule It - Important & Not Urgent
  static const kLevel1Color = Colors.amber; // Delegate It - Urgent & Not Important
  static const kLevel0Color = Colors.grey; // Eliminate It - Not Important & Not Urgent

  static Color? dueDateColor(DateTime? dateTime) {
    if (dateTime != null) {
      Duration duration = dateTime.difference(DateTime.now());
      if (duration > Duration.zero) {
        return kRemainingTextColor;
      } else {
        return kOverdueTextColor;
      }
    } else {
      return kDefaultTextColor;
    }
  }

  static Color? priorityColor(int priority) {
    switch (priority) {
      case 0:
        return kLevel0Color;
      case 1:
        return kLevel1Color;
      case 2:
        return kLevel2Color;
      case 3:
        return kLevel3Color;
      default:
        return kLevel0Color;
    }
  }

  
}
