import 'package:flutter/material.dart';




class AnimatedRobotIcon extends StatefulWidget {
  const AnimatedRobotIcon({super.key});

  @override
  State<AnimatedRobotIcon> createState() => _AnimatedRobotIconState();
}

class _AnimatedRobotIconState extends State<AnimatedRobotIcon> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('menu'),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _controller.value * -5),
            child: Transform.rotate(
              angle: _controller.value * 0.3,
              child: child,
            ),
          );
        },
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF41be8c), Color(0xFF3ECAA7)],
            transform: GradientRotation(0.785),
          ).createShader(bounds),
          child: const Icon(
            Icons.smart_toy, // Icône de robot moderne
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}