import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_app/screens/home_screen.dart';

import 'core/models.dart';
// ================================================================
// const String BASE_URL = 'http://localhost:8000';
const String BASE_URL = 'http://192.168.1.3:8000';
// جهاز حقيقي → 'http://192.168.1.X:8000'

//  COLORS
// ================================================================
const kBg      = Color(0xFFF8F9FA);
const kSurface = Color(0xFFFFFFFF);
const kBorder  = Color(0xFFE5E7EB);
const kAccent  = Color(0xFF1D9E75);
const kAccentL = Color(0xFFE1F5EE);
const kMuted   = Color(0xFF6B7280);
const kText    = Color(0xFF111827);
const kRed     = Color(0xFFA32D2D);
const kRedL    = Color(0xFFFCEBEB);
const kRedB    = Color(0xFFF09595);
const kYellow  = Color(0xFF854F0B);
const kYellowL = Color(0xFFFAEEDA);
const kYellowB = Color(0xFFFAC775);
const kGreen   = Color(0xFF3B6D11);
const kGreenL  = Color(0xFFEAF3DE);
const kGreenB  = Color(0xFFC0DD97);

void main() => runApp(const MediScanApp());

class MediScanApp extends StatelessWidget {
  const MediScanApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'SF Pro Text',
        colorScheme: const ColorScheme.light(
          primary: kAccent,
          secondary: kAccent,
          surface: kSurface,
          error: kRed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          hintStyle: const TextStyle(color: kMuted, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kAccent, width: 1.5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

//  API SERVICE
// ================================================================
class ApiService {
  static Future<List<String>> getAllSymptoms() async {
    final res = await http.get(Uri.parse('$BASE_URL/symptoms'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return List<String>.from(jsonDecode(res.body)['symptoms']);
    throw Exception('Failed to load symptoms');
  }

  static Future<PredictionResult> predict(List<String> symptoms) async {
    final res = await http.post(Uri.parse('$BASE_URL/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'symptoms': symptoms}),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return PredictionResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    throw Exception('Prediction failed: ${res.statusCode}');
  }

  static Future<String> chat({
    required String message,
    required String disease,
    required String risk,
    required List<String> symptoms,
    required List<Map<String, String>> history,
  }) async {
    final res = await http.post(Uri.parse('$BASE_URL/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message':  message,
        'disease':  disease,
        'risk':     risk,
        'symptoms': symptoms,
        'history':  history,
      }),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes))['reply'] as String;
    }
    throw Exception('Chat failed: ${res.statusCode}');
  }
}

// ================================================================


// ================================================================
//  LOADING DOTS
// ================================================================
