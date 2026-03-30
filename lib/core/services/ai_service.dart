import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static String get _apiKey => dotenv.env['API_KEY'] ?? '';
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

  static final Logger _logger = Logger();
  static Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    if (_apiKey.isEmpty) {
      return "Lỗi: API key không tồn tại. Kiểm tra file .env";
    }

    final Uri url = Uri.parse("$_baseUrl?key=$_apiKey");
    final String prompt = """
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
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 2048,
          },
        }),
      );
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decodedBody);
      if (response.statusCode == 200) {
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null) {
          final String text =
              data['candidates'][0]['content']['parts'][0]['text'];
          return text.trim();
        }
        return "AI không trả về nội dung.";
      }
      else {
        _logger.e("Lỗi API (${response.statusCode}): $decodedBody");
        return "Lỗi: ${data['error']?['message'] ?? 'Không rõ nguyên nhân'}";
      }
    } catch (e) {
      _logger.e("Lỗi kết nối: $e");
      return "Lỗi kết nối hệ thống.";
    }
  }
}