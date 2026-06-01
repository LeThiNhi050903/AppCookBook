import 'package:flutter/material.dart';

import '../../core/services/local_service.dart';

class AiNoteTab extends StatefulWidget {
  const AiNoteTab({super.key});

  @override
  State<AiNoteTab> createState() => _AiNoteTabState();
}

class _AiNoteTabState extends State<AiNoteTab> {
  final LocalService _localService = LocalService();
  List<Map<String, String>> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _localService.getAiNotes();
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _deleteNoteAt(int index) async {
    await _localService.deleteAiNoteAt(index);
    await _loadNotes();
  }

  void _openNoteDetail(int index) {
    final note = _notes[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiNoteDetailPage(
          title: note['title'] ?? 'Ghi chú AI',
          content: note['content'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return const EmptyStateWidget();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: _notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              note['title'] ?? 'Ghi chú AI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteNoteAt(index),
            ),
            onTap: () => _openNoteDetail(index),
          ),
        );
      },
    );
  }
}

class AiNoteDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const AiNoteDetailPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(title, style: const TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Image.asset(
              'images/no_recipe.jpg',
              width: 180,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              "Chưa có ghi chú nào",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Tất cả ghi chú AI bạn lưu sẽ xuất hiện ở đây",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
