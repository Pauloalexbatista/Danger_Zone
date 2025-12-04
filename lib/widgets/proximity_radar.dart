import 'package:flutter/material.dart';
import '../models/player.dart';

class ProximityRadar extends StatefulWidget {
  final ProximityLevel proximity;

  const ProximityRadar({super.key, required this.proximity});

  @override
  State<ProximityRadar> createState() => _ProximityRadarState();
}

class _ProximityRadarState extends State<ProximityRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ProximityRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proximity != widget.proximity) {
      _updateAnimationDuration();
    }
  }

  void _updateAnimationDuration() {
    switch (widget.proximity) {
      case ProximityLevel.veryClose:
        _controller.duration = const Duration(milliseconds: 300);
        break;
      case ProximityLevel.close:
        _controller.duration = const Duration(milliseconds: 800);
        break;
      case ProximityLevel.far:
      case ProximityLevel.unknown:
        _controller.duration = const Duration(seconds: 2);
        break;
    }
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color radarColor;
    String statusText;

    switch (widget.proximity) {
      case ProximityLevel.veryClose:
        radarColor = Colors.red;
        statusText = "PERIGO CRÍTICO!";
        break;
      case ProximityLevel.close:
        radarColor = Colors.orange;
        statusText = "ALERTA";
        break;
      case ProximityLevel.far:
      case ProximityLevel.unknown:
        radarColor = Colors.green;
        statusText = "SEGURO";
        break;
    }

    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: radarColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: radarColor.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Center(
              child: Icon(
                Icons.radar,
                size: 60,
                color: radarColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          statusText,
          style: TextStyle(
            color: radarColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
