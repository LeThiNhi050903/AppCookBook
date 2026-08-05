import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/recipe.dart';
import 'review_request_detail_screen.dart';

class ReviewRequestsScreen extends StatelessWidget {
  const ReviewRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService svc = FirebaseService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xét duyệt công thức',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: svc.getReviewRequestsForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final docs = snapshot.data?.docs ?? [];
          final pendingDocs = docs
              .where((doc) => (doc.data()['status'] as String?) == 'pending')
              .toList();
          if (pendingDocs.isEmpty) {
            return const Center(
              child: Text('Không có đơn nào đang chờ xét duyệt'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
            itemCount: pendingDocs.length,
            itemBuilder: (context, index) {
              final doc = pendingDocs[index];
              final recipe = Recipe.fromFirestore(doc);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewRequestDetailScreen(
                          requestId: doc.id,
                          recipe: recipe,
                          isAdminReview: true,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: recipe.thumbnail.isNotEmpty
                              ? Image.network(
                                  recipe.thumbnail,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe.authorName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.orange.shade100,
                                ),
                                child: const Text(
                                  'Đang xét duyệt',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
