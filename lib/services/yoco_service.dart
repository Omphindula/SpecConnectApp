
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';



class YocoService {
  static String get yocoApiKey => dotenv.env['YOCO_API_KEY'] ?? '';

  // Update with your backend URL
  static const String backendUrl = 'http://localhost:3000/pay';

  Future<bool> processPayment({
    required String cardToken,
    required int amount,
    required String currency,
    required Map<String, String> doctorBankDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: '''{
          "token": "$cardToken",
          "amount": $amount,
          "currency": "$currency",
          "doctorBankDetails": ${doctorBankDetails.toString()}
        }''',
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Payment error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Payment exception: $e');
      return false;
    }
  }
}
