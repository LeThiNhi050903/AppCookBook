import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanWeek extends StatelessWidget {
  const PlanWeek({super.key});
  List<DateTime> _getCurrentWeekDays() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    DateTime firstDayOfWeek = now.subtract(Duration(days: currentWeekday - 1));
    return List.generate(7, (index) => firstDayOfWeek.add(Duration(days: index)));
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return "Thứ hai";
      case 2: return "Thứ ba";
      case 3: return "Thứ tư";
      case 4: return "Thứ năm";
      case 5: return "Thứ sáu";
      case 6: return "Thứ bảy";
      case 7: return "Chủ nhật";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getCurrentWeekDays();
    final String currentMonthYear = DateFormat('MM/yyyy').format(DateTime.now());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left)),
              Text(
                "Tuần này ($currentMonthYear)", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              DateTime date = weekDays[index];
              String dayName = _getDayName(date.weekday);
              String dateStr = DateFormat('dd/MM/yyyy').format(date);              
              bool isToday = DateUtils.isSameDay(date, DateTime.now());
              return _buildDayItem(dayName, dateStr, isToday: isToday);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayItem(String day, String date, {bool isToday = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$day  $date", 
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday ? Colors.orange : Colors.black,
                fontSize: 16
              )
            ),
            IconButton(
              onPressed: () {}, 
              icon: const Icon(Icons.add, color: Colors.black54)
            ),
          ],
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isToday 
                ? Colors.orange.withValues(alpha: 0.05) 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isToday 
                ? Border.all(color: Colors.orange.withValues(alpha: 0.3)) 
                : null,
          ),
          child: const Text(
            "Không có công thức", 
            style: TextStyle(color: Colors.grey, fontSize: 14)
          ),
        ),
      ],
    );
  }
}