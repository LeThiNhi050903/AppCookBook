import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_plan.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/recipe.dart';
import '../recipe/recipe_detail_screen.dart';
class PlanWeek extends StatelessWidget {
  PlanWeek({super.key});

  final FirebaseService _firebase = FirebaseService();

  List<DateTime> _getCurrentWeekDays() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    DateTime firstDayOfWeek = now.subtract(
      Duration(days: currentWeekday - 1),
    );
    return List.generate(
      7,
      (index) => firstDayOfWeek.add(Duration(days: index)),
    );
  }
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Thứ hai";
      case 2:
        return "Thứ ba";
      case 3:
        return "Thứ tư";
      case 4:
        return "Thứ năm";
      case 5:
        return "Thứ sáu";
      case 6:
        return "Thứ bảy";
      case 7:
        return "Chủ nhật";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getCurrentWeekDays();
    final currentMonthYear =
        DateFormat('MM/yyyy').format(DateTime.now());
    final currentUid = _firebase.currentUserId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              "Tuần này ($currentMonthYear)",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        Expanded(
          child: currentUid == null
              ? const Center(child: Text('Vui lòng đăng nhập'))
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firebase.streamUserPlans(currentUid),
                  builder: (context, snap) {
                    final plans = snap.data ?? [];
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: weekDays.length,
                      itemBuilder: (context, index) {
                        final date = weekDays[index];
                        final dayName = _getDayName(date.weekday);
                        final dateStr = DateFormat('dd/MM/yyyy').format(date);
                        final isToday = DateUtils.isSameDay(date, DateTime.now());
                        final dayPlans = plans.where((p) {
                          final d = p['date'];
                          if (d is Timestamp) {
                            return DateUtils.isSameDay(d.toDate(), date);
                          } else if (d is DateTime) {
                            return DateUtils.isSameDay(d, date);
                          }
                          return false;
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$dayName  $dateStr",
                                  style: TextStyle(
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                    color: isToday ? Colors.orange : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => CreatePlanScreen(initialPlan: {'date': date},),),
                                    );
                                    if (res == true) {
                                      // refresh handled by stream
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isToday ? Colors.orange.withValues(alpha: 0.05) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: isToday
                                    ? Border.all(
                                        color: Colors.orange.withValues(alpha: 0.3),
                                      )
                                    : null,
                              ),
                              child: dayPlans.isEmpty
                                  ? const Text(
                                      "Không có công thức",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    )
                                  : Column(
                                      children: dayPlans.map((p) {
                                        final recipeId = p['recipeId'] as String? ?? '';
                                        final mealText = p['meal'] as String? ?? '';
                                        final qty = p['quantity'] as int? ?? 1;
                                        final planId = p['id'] as String? ?? '';
                                        return FutureBuilder<Recipe?>(
                                          future: _firebase.getRecipeById(recipeId),
                                          builder: (context, rSnap) {
                                            final recipe = rSnap.data;
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: recipe == null
                                                  ? const SizedBox(width: 70, height: 70)
                                                  : ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: InkWell(
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                                                          );
                                                        },
                                                        child: Image.network(
                                                          recipe.thumbnail,
                                                          width: 70,
                                                          height: 70,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                              title: Text(mealText, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              subtitle: Text('Số lượng: $qty'),
                                              trailing: PopupMenuButton<String>(
                                                onSelected: (v) async {
                                                  if (v == 'delete') {
                                                    await _firebase.deletePlan(planId);
                                                  } else if (v == 'edit') {
                                                    final res = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (_) => CreatePlanScreen(planId: planId, initialPlan: p)),
                                                    );
                                                    if (res == true) {
                                                      // saved
                                                    }
                                                  }
                                                },
                                                itemBuilder: (_) => [
                                                  const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                                                  const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  
  // old helper removed — UI built inline in build()
}