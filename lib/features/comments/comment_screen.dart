import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/models/comments.dart';
import '../../data/models/recipe.dart';
import '../../core/widgets/avatar.dart';
import '../../core/services/comments_service.dart';
import 'comments_title.dart';

class CommentScreen extends StatefulWidget {
  final Recipe recipe;
  final bool autoFocus;
  const CommentScreen({
    super.key,
    required this.recipe,
    this.autoFocus = false,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final CommentService _commentService = CommentService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final String _currentUid;
  String _username = '';
  String _avatar = '';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _currentUid = _auth.currentUser!.uid;
    _loadCurrentUser();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final doc = await _firestore
        .collection('users')
        .doc(_currentUid)
        .get();
    if (!mounted) return;
    final data = doc.data();
    if (data == null) return;
    setState(() {
      _username = data['username'] ?? 'Người dùng';
      _avatar = data['avatar'] ?? '';
    });
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text("Báo cáo"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text("Chặn"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }  

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.recipe.thumbnail,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    width: 52,
                    height: 52,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.recipe.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: _showMoreMenu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            UserAvatar(
              username: _username,
              isLoading: false,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autoFocus,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: "Viết bình luận...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _sending ? null : _sendComment,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.deepOrange,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
    });
    try {
      await _commentService.addComment(
        recipeId: widget.recipe.id,
        username: _username,
        avatar: _avatar,
        content: text,
      );
      _controller.clear();
      _focusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Không thể gửi bình luận.",
            ),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _commentService.getComments(
                widget.recipe.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Không thể tải bình luận",
                    ),
                  );
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      "Chưa có bình luận nào",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 80,
                  ),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) =>
                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentTile(
                      comment: comment,
                      currentUid: _currentUid,
                      onLike: () async {
                        await _commentService.toggleLike(
                          recipeId: widget.recipe.id,
                          comment: comment,
                        );
                      },
                      onMore: _showMoreMenu,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }  


}
