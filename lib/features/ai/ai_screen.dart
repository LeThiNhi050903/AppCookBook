import 'package:flutter/material.dart';
import 'chat_bubble.dart';
import 'input.dart';
import 'tab_ai.dart'; 
import '../../core/services/ai_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;
  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;
    String text = controller.text.trim();
    setState(() {
      messages.add({"role": "user", "content": text});
      isLoading = true;
    });
    controller.clear();
    scrollToBottom();
    try {
      String reply = await AIService.sendMessage(text);
      setState(() {
        messages.add({"role": "ai", "content": reply});
      });
    } catch (e) {
      setState(() {
        messages.add({
          "role": "ai",
          "content": "Lỗi kết nối AI"
        });
      });
    }
    setState(() => isLoading = false);
    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void newChat() {
    setState(() {
      messages.clear();
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(onNewChat: newChat), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatBubble(
                  text: msg["content"]!,
                  isUser: msg["role"] == "user",
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ChatInput(
            controller: controller,
            onSend: sendMessage,
          )
        ],
      ),
    );
  }
}