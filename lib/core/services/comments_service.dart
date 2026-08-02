import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/comments.dart';

class CommentService {
  CommentService._();
  static final CommentService instance = CommentService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> _commentRef(
    String recipeId,
  ) {
    return _firestore
        .collection("recipes")
        .doc(recipeId)
        .collection("comments");
  }

  Stream<List<CommentModel>> getComments(String recipeId) {
    return _commentRef(recipeId)
        .orderBy(
          "createdAt",
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((e) => CommentModel.fromFirestore(e))
              .toList(),
        );
  }

  Future<void> addComment({
    required String recipeId,
    required String username,
    required String avatar,
    required String content,
  }) async {
    final uid = _auth.currentUser!.uid;

    await _commentRef(recipeId).add({
      "uid": uid,
      "username": username,
      "avatar": avatar,
      "content": content.trim(),
      "createdAt": Timestamp.now(),
      "likedUsers": <String>[],
    });
  }

  Future<void> toggleLike({
    required String recipeId,
    required CommentModel comment,
  }) async {
    final uid = _auth.currentUser!.uid;
    final doc = _commentRef(recipeId).doc(comment.id);
    if (comment.likedUsers.contains(uid)) {
      await doc.update({
        "likedUsers": FieldValue.arrayRemove([uid]),
      });
    } else {
      await doc.update({
        "likedUsers": FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> deleteComment({
    required String recipeId,
    required String commentId,
  }) async {
    await _commentRef(recipeId)
        .doc(commentId)
        .delete();
  }
}