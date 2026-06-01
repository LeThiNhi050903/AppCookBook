import 'package:flutter/material.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Điều khoản & Chính sách"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            context,
            icon: Icons.description_outlined,
            title: "Điều khoản sử dụng",
            subtitle: "Quy định khi sử dụng ứng dụng",
            content: _termsContent,
          ),

          const SizedBox(height: 12),

          _buildCard(
            context,
            icon: Icons.privacy_tip_outlined,
            title: "Chính sách bảo mật",
            subtitle: "Thông tin về dữ liệu người dùng",
            content: _privacyContent,
          ),

          const SizedBox(height: 12),

          _buildCard(
            context,
            icon: Icons.smart_toy_outlined,
            title: "Chính sách sử dụng AI",
            subtitle: "Thông tin về tính năng AI",
            content: _aiContent,
          ),

          const SizedBox(height: 24),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email_outlined),
                    title: Text("Liên hệ hỗ trợ"),
                    subtitle: Text("support@cookbookai.com"),
                  ),
                  Divider(),
                  Text(
                    "Phiên bản 1.0.0",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "© 2026 CookBook AI",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String content,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Text(content),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đóng"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const String _termsContent = '''
1. Người dùng chịu trách nhiệm về thông tin tài khoản của mình.

2. Không sử dụng ứng dụng cho mục đích vi phạm pháp luật.

3. Nội dung do AI tạo ra chỉ mang tính tham khảo.

4. Nhà phát triển có quyền cập nhật ứng dụng và điều khoản khi cần thiết.
''';

const String _privacyContent = '''
1. Ứng dụng lưu trữ thông tin tài khoản cần thiết để cung cấp dịch vụ.

2. Dữ liệu cá nhân không được chia sẻ cho bên thứ ba khi chưa có sự đồng ý của người dùng.

3. Dữ liệu có thể được sử dụng để cải thiện trải nghiệm người dùng.
''';

const String _aiContent = '''
1. Tính năng AI hỗ trợ gợi ý công thức nấu ăn và giải đáp thắc mắc.

2. Kết quả do AI tạo ra có thể không hoàn toàn chính xác.

3. Người dùng nên kiểm tra lại thông tin trước khi áp dụng vào thực tế.
''';