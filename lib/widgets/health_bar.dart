import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  final double health; // 0 to 100

  const HealthBar({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    // Color logic: Green > 50%, Orange > 20%, Red < 20%
    Color barColor = Colors.green;
    if (health < 20) {
      barColor = Colors.red;
    } else if (health < 50) {
      barColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "VIDA: ${health.toInt()}%",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: health / 100,
            backgroundColor: Colors.grey[800],
            color: barColor,
            minHeight: 20,
          ),
        ),
      ],
    );
  }
}
