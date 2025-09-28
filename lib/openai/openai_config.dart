import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIConfig {
  static const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY', defaultValue: '');
  static const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT', defaultValue: '');
  
  static bool get isConfigured => apiKey.isNotEmpty && endpoint.isNotEmpty;

  static Future<String> generateResponse({
    required String systemPrompt,
    required String userMessage,
    String model = 'gpt-4o-mini',
    int maxTokens = 500,
    double temperature = 0.7,
  }) async {
    // If OpenAI is not configured, return fallback response
    if (!isConfigured) {
      return _generateFallbackResponse(userMessage);
    }
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenAI API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback response on error
      return _generateFallbackResponse(userMessage);
    }
  }

  static Future<Map<String, dynamic>> generateJsonResponse({
    required String systemPrompt,
    required String userMessage,
    String model = 'gpt-4o-mini',
    int maxTokens = 500,
    double temperature = 0.7,
  }) async {
    // If OpenAI is not configured, return fallback JSON response
    if (!isConfigured) {
      return _generateFallbackJsonResponse(userMessage);
    }
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('OpenAI API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback JSON response on error
      return _generateFallbackJsonResponse(userMessage);
    }
  }
  
  static String _generateFallbackResponse(String userMessage) {
    // Simple rule-based fallback responses
    final message = userMessage.toLowerCase();
    
    if (message.contains('appointment') || message.contains('book')) {
      return '''I can help you book an appointment! Here's what I can do:

• Book appointments with available doctors
• Check doctor availability and specializations
• Provide appointment scheduling assistance

To book an appointment, please use the "Book Appointment" button on your dashboard or tell me:
- What type of doctor you need (e.g., cardiologist, dentist)
- Your preferred date and time
- Any special requirements

For urgent medical needs, please contact emergency services at 10111 or 112.''';
    }
    
    if (message.contains('emergency') || message.contains('urgent') || message.contains('pain')) {
      return '''⚠️ For medical emergencies, please:

1. CALL 10111 or 112 immediately for life-threatening emergencies
2. Go to the nearest emergency room
3. Contact your doctor directly for urgent but non-life-threatening issues

I'm here to help with appointment booking and general health information, but cannot provide emergency medical advice.''';
    }
    
    if (message.contains('doctor') || message.contains('specialist')) {
      return '''I can help you find and book appointments with doctors! Available specializations include:

• General Practice
• Cardiology
• Dermatology  
• Pediatrics
• Orthopedics
• And more...

To find a doctor:
1. Go to the "Doctors" tab on your dashboard
2. Search by name, specialization, or location
3. View doctor profiles and availability
4. Book appointments directly

Would you like help finding a specific type of doctor?''';
    }
    
    return '''Hello! I'm your MediConnect AI assistant. I can help you with:

🏥 **Appointment Booking**
• Schedule appointments with doctors
• Find specialists by location
• Check availability and fees

📋 **Health Information**
• General health guidance
• Answer basic medical questions
• Medication reminders

🚨 **Emergency Support**
• Emergency contact information
• First aid guidance
• Direct emergency services access

How can I assist you today? You can ask me questions like:
- "Book me an appointment with a cardiologist"
- "Find doctors near me"
- "What should I do for chest pain?"

*Note: For emergencies, call 10111 or 112 immediately.*''';
  }
  
  static Map<String, dynamic> _generateFallbackJsonResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Try to detect appointment booking intent
    if (message.contains('book') && message.contains('appointment')) {
      return {
        'action': 'general_response',
        'response_message': 'I\'d be happy to help you book an appointment! Please use the "Book Appointment" button on your dashboard to schedule with an available doctor. You can choose your preferred date, time, and specialist type.'
      };
    }
    
    return {
      'action': 'general_response',
      'response_message': _generateFallbackResponse(userMessage)
    };
  }
}