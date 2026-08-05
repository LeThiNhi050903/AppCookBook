import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPlanScreen extends StatefulWidget {
  final DateTime selectedDate;
  const CalendarPlanScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<CalendarPlanScreen> createState() =>
      _CalendarPlanScreenState();
}

class _CalendarPlanScreenState extends State<CalendarPlanScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _selectedDay = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: (){
            Navigator.pop(context);
          },
          child: const Text(
            "Hủy",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.pop(
                context,
                _selectedDay,
              );
            },
            child: const Text(
              "Lưu",
              style: TextStyle(
                color: Colors.green,
              ),
            ),
          )
        ],
      ),
      body: TableCalendar(
        locale: 'en_US',
        firstDay: DateTime(2020),
        lastDay: DateTime(2050),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day){
          return isSameDay(
            day,
            _selectedDay,
          );
        },
        onDaySelected: (
          selectedDay,
          focusedDay,
        ){
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}