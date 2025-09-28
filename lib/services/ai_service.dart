import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  /// Returns a friendly multi-line welcome message.
  Future<String> getChatWelcomeMessage() async {
    return '''
Welcome to Karabo AI Assistant!

Here’s what I can help you with:
- Book appointments with doctors
- Get medication reminders
- Reschedule or cancel appointments
- General health questions
- Emergency guidance

Type your question or request below and I’ll do my best to assist you!
''';
  }

  /// Sends an appointment-related message to Gemini and returns the AI’s response.
  Future<String> processAppointmentRequest(String userMessage, String patientId) async {
    final prompt = '''
You are a helpful medical assistant for SpecConnect, a healthcare platform for the University of Mpumalanga. Your role is to help patients with appointment scheduling, provide general health information, and assist with healthcare-related questions.

Current date and time: ${DateTime.now()}
Patient ID: $patientId
User: $userMessage
''';
    return await _sendToGemini(prompt);
  }

  /// Sends an emergency query to Gemini and returns the AI’s response.
  Future<String> processEmergencyRequest(String userMessage) async {
    final prompt = '''
🚨 EMERGENCY QUERY 🚨
User: $userMessage

If this is a life-threatening emergency, call 10111 or 112 immediately!
Otherwise, provide calm, clear, and actionable guidance.
''';
    return await _sendToGemini(prompt);
  }

  /// Internal method to send a prompt to Gemini and return the AI’s response.
  Future<String> _sendToGemini(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey', // Bearer token authentication
        },
        body: jsonEncode({
          "prompt": prompt,
          "temperature": 0.7,
          "candidate_count": 1,
          "max_output_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Gemini response: candidates[0].content[0].text
        return data['candidates']?[0]?['content']?[0]?['text'] ?? 'No response from AI.';
      } else {
        return 'Error ${response.statusCode}: ${response.reasonPhrase}\n${response.body}';
      }
    } catch (e) {
      return 'Sorry, something went wrong while contacting the AI service.';
    }
  }
}
