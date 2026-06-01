import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_bubble.dart';
import 'input.dart';
import 'tab_ai.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/local_service.dart';

enum AiFeedback { none, liked, disliked }

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final LocalService localService = LocalService();

  List<Map<String, String>> messages = [];
  List<List<Map<String, String>>> chatHistory = [];
  int currentChatIndex = -1;
  bool isLoading = false;
  final Map<int, AiFeedback> responseFeedback = {};

  @override
  void initState() {
    super.initState();
    _loadAiChatHistory();
  }

  Future<void> _loadAiChatHistory() async {
    final loaded = await localService.getAiChatHistory();
    if (!mounted) return;
    setState(() {
      chatHistory = loaded;
    });
  }

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
      await localService.saveAiChatHistory(chatHistory);
    } catch (e) {
      setState(() {
        messages.add({
          "role": "ai",
          "content": "Lỗi kết nối AI. Vui lòng thử lại.",
        });
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
      responseFeedback.clear();
    });
    Navigator.pop(context);
  }

  void loadChat(int index) {
    setState(() {
      messages = List.from(chatHistory[index]);
      currentChatIndex = index;
      responseFeedback.clear();
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
    localService.saveAiChatHistory(chatHistory);
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
                responseFeedback.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
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
                      if (msg["role"] == "user") {
                        return ChatBubble(text: msg["content"]!, isUser: true);
                      }
                      final feedback =
                          responseFeedback[index] ?? AiFeedback.none;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChatBubble(text: msg["content"]!, isUser: false),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6, top: 4, bottom: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Lưu vào ghi chú
                                  GestureDetector(
                                    onTap: () async {
                                      final response = msg["content"];
                                      if (response == null) return;

                                      final messenger = ScaffoldMessenger.of(context);
                                      final userQuestion = index > 0 && messages[index - 1]["role"] == "user"
                                          ? messages[index - 1]["content"] ?? "Câu hỏi"
                                          : "Câu hỏi";

                                      await localService.saveAiNote(response, userQuestion: userQuestion);

                                      if (!mounted) return;

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã lưu ghi chú AI'),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white,
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.push_pin_outlined,
                                            size: 16,
                                            color: Colors.black54,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            "Lưu vào ghi chú",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Copy
                                  GestureDetector(
                                    onTap: () async {
                                      final response = msg["content"];
                                      if (response == null) return;

                                      final messenger = ScaffoldMessenger.of(context);

                                      await Clipboard.setData(
                                        ClipboardData(text: response),
                                      );

                                      if (!mounted) return;

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã sao chép câu trả lời'),
                                          duration: Duration(milliseconds: 900),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.copy_outlined,
                                        size: 20,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Like
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        responseFeedback[index] =
                                            feedback == AiFeedback.liked
                                                ? AiFeedback.none
                                                : AiFeedback.liked;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.thumb_up_alt_outlined,
                                        size: 20,
                                        color: feedback == AiFeedback.liked
                                            ? Colors.orange
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Unlike
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        responseFeedback[index] =
                                            feedback == AiFeedback.disliked
                                                ? AiFeedback.none
                                                : AiFeedback.disliked;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.thumb_down_alt_outlined,
                                        size: 20,
                                        color: feedback == AiFeedback.disliked
                                            ? Colors.orange
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(color: Colors.orange),
            ),
          ChatInput(controller: controller, onSend: sendMessage),
        ],
      ),
    );
  }
}
