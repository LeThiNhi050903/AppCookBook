import 'package:flutter/material.dart';
import '../../features/plan/plan_screen.dart';
import '../../features/ai/ai_screen.dart';

class AiPlantButton extends StatelessWidget {
  const AiPlantButton({super.key});
  String _getTodayWeekday() {
    int weekday = DateTime.now().weekday;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Spacer(),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.push_pin_outlined, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  _getTodayWeekday(), 
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4), 
                const VerticalDivider(
                  indent: 14,
                  endIndent: 14,
                  thickness: 1,
                  width: 24, 
                  color: Colors.grey,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlanScreen(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    size: 19,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 14), 
              ],
            ),
          ),         
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiScreen(),
                ),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}