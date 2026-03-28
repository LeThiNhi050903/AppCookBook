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
  List<List<Map<String, String>>> chatHistory = [];
  int currentChatIndex = -1;
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
      List<Map<String, String>> history = List.from(messages)..removeLast();
      String reply = await AIService.sendMessage(text, history);

      setState(() {
        messages.add({"role": "ai", "content": reply});
        if (currentChatIndex == -1) {
          chatHistory.add(List.from(messages));
          currentChatIndex = chatHistory.length - 1;
        } else {
          chatHistory[currentChatIndex] = List.from(messages);
        }
      });
    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "content": "Lỗi kết nối AI. Vui lòng thử lại."});
      });
    }
    
    setState(() => isLoading = false);
    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void newChat() {
    setState(() {
      messages = [];
      currentChatIndex = -1;
    });
    Navigator.pop(context); 
  }

  void loadChat(int index) {
    setState(() {
      messages = List.from(chatHistory[index]);
      currentChatIndex = index;
    });
    Navigator.pop(context); 
  }

  void deleteChat(int index) {
    setState(() {
      chatHistory.removeAt(index);
      if (currentChatIndex == index) {
        messages = [];
        currentChatIndex = -1;
      } else if (currentChatIndex > index) {
        currentChatIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(
        onNewChat: newChat,
        chatHistory: chatHistory,
        onSelectChat: loadChat,
        onDeleteChat: deleteChat,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("AI Chef", style: TextStyle(color: Colors.black)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              setState(() {
                messages = [];
                currentChatIndex = -1;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty 
              ? const Center(child: Text("Hãy bắt đầu hỏi công thức nấu ăn!"))
              : ListView.builder(
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
              child: LinearProgressIndicator(color: Colors.orange),
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