import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_plan.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/recipe.dart';
import '../recipe/recipe_detail_screen.dart';

class PlanMonth extends StatefulWidget {
  const PlanMonth({super.key});

  @override
  State<PlanMonth> createState() => _PlanMonthState();
}

class _PlanMonthState extends State<PlanMonth> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  final FirebaseService _firebase = FirebaseService();
  String _getVietnameseWeekday(DateTime date) {
    switch (date.weekday) {
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
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              TableCalendar(
                locale: 'en_US',
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                selectedDayPredicate: (day) =>
                    isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${_getVietnameseWeekday(_selectedDay!)} - ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firebase.streamUserPlans(_firebase.auth.currentUser?.uid ?? ''),
                builder: (context, snap) {
                  final plans = snap.data ?? [];
                  final dayPlans = plans.where((p) {
                    final d = p['date'];
                    if (d is Timestamp) return DateUtils.isSameDay(d.toDate(), _selectedDay);
                    if (d is DateTime) return DateUtils.isSameDay(d, _selectedDay);
                    return false;
                  }).toList();
                  if (dayPlans.isEmpty) return _buildEmptyState();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: dayPlans.map((p) {
                        final recipeId = p['recipeId'] as String? ?? '';
                        final meal = p['meal'] as String? ?? '';
                        final qty = p['quantity'] as int? ?? 1;
                        final planId = p['id'] as String? ?? '';
                        return FutureBuilder<Recipe?>(
                          future: _firebase.getRecipeById(recipeId),
                          builder: (context, rSnap) {
                            final recipe = rSnap.data;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: recipe == null
                                    ? const SizedBox(width: 70, height: 70)
                                    : InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            recipe.thumbnail,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                title: Text(meal, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                                        // handled by stream
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                                    const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.orange,
            elevation: 4,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreatePlanScreen(),
                ),
              );
            },
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Không có công thức cho ngày này",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }
}