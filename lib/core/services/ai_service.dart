import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class AIService {
  static const String _apiKey = "AIzaSyDXxZraSjCKIWmEklQ-hAWuHCPYopPJie0";
  static const String _baseUrl = 
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

  static final _logger = Logger();

  static Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    final url = Uri.parse("$_baseUrl?key=$_apiKey");

    String prompt = """
Bạn là một đầu bếp chuyên nghiệp. Hãy hỗ trợ người dùng nấu ăn, gợi ý công thức phù hợp với nhu cầu và sở thích của người dùng.
Lịch sử chat:
${history.map((m) => "${m['role']}: ${m['content']}").join("\n")}

Câu hỏi hiện tại: $message
Trả lời bằng tiếng Việt, định dạng rõ ràng:
- Tên món:
- Nguyên liệu:
- Các bước thực hiện:
- Lưu ý dinh dưỡng:
""";

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [{"text": prompt}]
            }
          ],
          "generationConfig": {
            "thinkingConfig": {
              "thinkingLevel": "HIGH", 
            },
            "temperature": 0.7,
            "maxOutputTokens": 2048,
          },
        }),
      );

      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final String text = data['candidates'][0]['content']['parts'][0]['text'];
          return text.trim();
        }
        return "AI không trả về nội dung.";
      } else {
        _logger.e("Lỗi API (${response.statusCode}): $decodedBody");
        return "Lỗi: ${data['error']?['message'] ?? 'Không rõ nguyên nhân'}";
      }
    } catch (e) {
      _logger.e("Lỗi kết nối: $e");
      return "Lỗi kết nối hệ thống.";
    }
  }
}