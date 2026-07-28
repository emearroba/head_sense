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
