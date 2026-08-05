import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/recipe.dart';

class ReviewRequestDetailScreen extends StatefulWidget {
  final String requestId;
  final Recipe recipe;
  final bool isAdminReview;

  const ReviewRequestDetailScreen({
    super.key,
    required this.requestId,
    required this.recipe,
    this.isAdminReview = false,
  });

  @override
  State<ReviewRequestDetailScreen> createState() => _ReviewRequestDetailScreenState();
}

class _ReviewRequestDetailScreenState extends State<ReviewRequestDetailScreen> {
  final FirebaseService _svc = FirebaseService();
  bool _isProcessing = false;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    final success = await _svc.approveReviewRequest(widget.requestId);
    setState(() => _isProcessing = false);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thông qua công thức')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lý do từ chối'),
          content: TextField(
            controller: reasonController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do từ chối...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
    if (result != true || reasonController.text.trim().isEmpty) return;
    setState(() => _isProcessing = true);
    final success = await _svc.rejectReviewRequest(widget.requestId, reasonController.text.trim());
    setState(() => _isProcessing = false);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối và gửi phản hồi')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xem công thức',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipe.thumbnail.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      recipe.thumbnail,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.orange,
                      child: Text(
                        recipe.authorName.isNotEmpty
                            ? recipe.authorName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.authorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.authorLocation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nguyên liệu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...recipe.ingredients.map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      ingredient,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Các bước chế biến',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...recipe.steps.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bước ${step.stepNumber}: ${step.title.isNotEmpty ? step.title : ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!widget.isAdminReview)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trạng thái đơn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.recipe.status == 'pending'
                              ? 'Đang xét duyệt'
                              : widget.recipe.status == 'approved'
                                  ? 'Đã thông qua'
                                  : widget.recipe.status == 'rejected'
                                      ? 'Đã từ chối'
                                      : widget.recipe.status,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.orange,
                          ),
                        ),
                        if (widget.recipe.reviewReason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Lý do: ${widget.recipe.reviewReason}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (widget.isAdminReview)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _reject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _approve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Thông qua'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
