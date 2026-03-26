import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String apiKey = "YOUR_API_KEY";

  static Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "Bạn là một đầu bếp, chuyên trả lời về ẩm thực và gợi ý món ăn."
          },
          {
            "role": "user",
            "content": message
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}