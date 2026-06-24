import 'package:flutter/material.dart';

class PulseIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const PulseIndicator({
    super.key,
    required this.color,
    this.size = 14.0,
  });

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulsePainter(
              animationValue: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _PulsePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw background concentric ring 1
    final paint1 = Paint()
      ..color = color.withValues(alpha: (1.0 - animationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * animationValue, paint1);

    // Draw background concentric ring 2
    final value2 = (animationValue + 0.5) % 1.0;
    final paint2 = Paint()
      ..color = color.withValues(alpha: (1.0 - value2).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * value2, paint2);

    // Draw inner solid center dot
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}
