import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/avatar.dart';
import '../../data/models/comments.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final String currentUid;
  final VoidCallback onLike;
  final VoidCallback onMore;
  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUid,
    required this.onLike,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final liked = comment.isLiked(currentUid);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            username: comment.username,
            isLoading: false,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onMore,
                      splashRadius: 18,
                      icon: const Icon(
                        Icons.more_horiz,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            liked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: liked
                                ? Colors.red
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${comment.likesCount}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      DateFormat(
                        "dd/MM/yyyy HH:mm",
                      ).format(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}