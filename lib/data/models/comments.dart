import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String uid;
  final String username;
  final String avatar;
  final String content;
  final DateTime createdAt;
  final List<String> likedUsers;
  const CommentModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.avatar,
    required this.content,
    required this.createdAt,
    this.likedUsers = const [],
  });
  int get likesCount => likedUsers.length;
  bool isLiked(String uid) {
    return likedUsers.contains(uid);
  }
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      avatar: data['avatar'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likedUsers: List<String>.from(
        data['likedUsers'] ?? [],
      ),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'avatar': avatar,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likedUsers': likedUsers,
    };
  }
  CommentModel copyWith({
    String? id,
    String? uid,
    String? username,
    String? avatar,
    String? content,
    DateTime? createdAt,
    List<String>? likedUsers,
  }) {
    return CommentModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likedUsers: likedUsers ?? this.likedUsers,
    );
  }
}