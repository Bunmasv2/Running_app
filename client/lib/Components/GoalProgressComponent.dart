import 'package:flutter/material.dart';
import '../Models/RunModel.dart';

class GoalProgressComponent extends StatelessWidget {
  final DailyGoal? goal; // Có thể null nếu chưa đặt mục tiêu
  final VoidCallback onSetGoal;

  const GoalProgressComponent({super.key, this.goal, required this.onSetGoal});

  @override
  Widget build(BuildContext context) {
    // TRƯỜNG HỢP 1: Chưa có mục tiêu (Hiển thị nút +)
    if (goal == null) {
      return GestureDetector(
        onTap: onSetGoal,
        child: Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
            // SỬA LỖI TẠI ĐÂY: Đổi sang solid và làm mờ màu border
            border: Border.all(
                color: Colors.blueAccent.withOpacity(0.5),
                width: 2,
                style: BorderStyle.solid
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_circle_outline, size: 50, color: Colors.blueAccent),
              SizedBox(height: 8),
              Text(
                  "Đặt mục tiêu ngay",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold
                  )
              ),
            ],
          ),
        ),
      );
    }

    // TRƯỜNG HỢP 2: Đã có mục tiêu -> Hiển thị Circular Progress
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Vòng tròn nền (màu xám nhạt)
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 15,
            color: Colors.grey.shade200,
          ),
          // Vòng tròn tiến độ (màu cam)
          CircularProgressIndicator(
            value: goal!.progress > 1.0 ? 1.0 : goal!.progress, // Max là 100%
            strokeWidth: 15,
            color: Colors.orange,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.transparent,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${(goal!.progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              Text(
                "Mục tiêu: ${goal!.targetDistanceKm} km",
                style: const TextStyle(color: Colors.grey),
              )
            ],
          )
        ],
      ),
    );
  }
}