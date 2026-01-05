import 'package:flutter/material.dart';
import '../Views/HomeView.dart'; // Để dùng class DailyGoal

class GoalProgressComponent extends StatelessWidget {
  final DailyGoal? goal;
  final VoidCallback onSetGoal;

  const GoalProgressComponent({
    super.key,
    required this.goal,
    required this.onSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu chưa đặt mục tiêu -> Hiện nút "Đặt mục tiêu"
    if (goal == null) {
      return GestureDetector(
        onTap: onSetGoal,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, size: 40, color: Colors.blue),
              SizedBox(height: 10),
              Text("Đặt mục tiêu", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // Nếu đã có mục tiêu -> Vẽ vòng tròn Progress
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: goal!.progress,
            strokeWidth: 15,
            backgroundColor: Colors.grey[200],
            color: Colors.blueAccent,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run, color: Colors.blue, size: 30),
            const SizedBox(height: 5),
            Text(
              goal!.currentDistanceKm.toStringAsFixed(2),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              "/ ${goal!.targetDistanceKm.toStringAsFixed(0)} km",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        )
      ],
    );
  }
}