import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  final String apiUrl;

  GeminiService({required this.apiKey, this.apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'});

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('$apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
            
          {'parts': [{'text': message}]}
        ]
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'No response';
    } else {
      throw Exception('Failed to get response: ${response.body}');
    }
  }
}
