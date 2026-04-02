import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class PlanMonth extends StatefulWidget {
  const PlanMonth({super.key});
  @override
  State<PlanMonth> createState() => _PlanMonthState();
}

class _PlanMonthState extends State<PlanMonth> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String _getVietnameseWeekday(DateTime date) {
    switch (date.weekday) {
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
    return Column(
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
              shape: BoxShape.circle
            ),
            todayDecoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.3), 
              shape: BoxShape.circle
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.orange, 
              shape: BoxShape.circle
            ),
          ),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay; 
            });
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "${_getVietnameseWeekday(_selectedDay!)} - ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        _buildEmptyState(),       
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 20, right: 20),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        )
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
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}