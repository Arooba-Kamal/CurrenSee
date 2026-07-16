import 'package:flutter/material.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key}) ;

  @override
  Widget build(BuildContext context) {
    // Simple placeholder for a trend chart. Replace with a real chart package as needed.
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withAlpha(((0.02) * 255).round())], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Center(
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.6),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.45, size.height * 0.55),
      Offset(size.width * 0.6, size.height * 0.35),
      Offset(size.width * 0.75, size.height * 0.42),
      Offset(size.width * 0.9, size.height * 0.25),
      Offset(size.width, size.height * 0.18),
    ];

    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

