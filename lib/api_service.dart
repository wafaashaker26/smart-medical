import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "http://127.0.0.1:8000";
  static Future<Map<String, dynamic>> predict(List<String> symptoms) async {
    final res = await http.post(
      Uri.parse("$baseUrl/predict"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"symptoms": symptoms}),
    );

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> chat(List history) async {
    final res = await http.post(
      Uri.parse("$baseUrl/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"history": history}),
    );

    return jsonDecode(res.body);
  }
}