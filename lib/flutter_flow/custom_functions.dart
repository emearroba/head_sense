import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/structs/index.dart';
import '/auth/firebase_auth/auth_util.dart';

// Shared by the Results tab and the Dashboard's Tracking Progress card so
// the streak math can't drift between the two. `sortedDateKeys` must be
// ascending "yyyy-MM-dd" strings (already deduped) of completed diary days.
int calculateLoggingStreak(List<String> sortedDateKeys) {
  if (sortedDateKeys.isEmpty) return 0;
  final dates = sortedDateKeys.map(DateTime.parse).toList();
  var streak = 1;
  for (var i = dates.length - 1; i > 0; i--) {
    final gap = dates[i].difference(dates[i - 1]).inDays;
    if (gap == 1) {
      streak++;
    } else if (gap == 0) {
      continue;
    } else {
      break;
    }
  }
  final today = DateTime.now();
  final todayKey = DateTime(today.year, today.month, today.day);
  final lastDate = dates.last;
  final gapFromToday = todayKey
      .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
      .inDays;
  return gapFromToday > 1 ? 0 : streak;
}

List<Color> getBarColors(List<DailyValueStruct> dailyValues) {
  if (dailyValues.isEmpty) {
    return <Color>[];
  }

  return dailyValues.map((item) {
    final String? hex = item.barColor;

    if (hex == null || hex.trim().isEmpty) {
      return Colors.grey;
    }

    String cleanHex = hex.trim().replaceFirst('#', '');

    // Añade opacidad completa cuando solo viene RRGGBB.
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }

    final int? colorValue = int.tryParse(cleanHex, radix: 16);

    if (colorValue == null) {
      return Colors.grey;
    }

    return Color(colorValue);
  }).toList();
}
