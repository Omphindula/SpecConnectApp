import 'package:flutter/material.dart';
import 'dart:math' as math;

class UMPLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const UMPLogo({
    super.key,
    this.size = 100,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + (showText ? 25 : 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/ump_logo.png',
                fit: BoxFit.cover,
                width: size,
                height: size,
              ),
            ),
          ),
          if (showText) ...[
            const SizedBox(
              height: 25,
            ),
            Text(
              'University of Mpumalanga',
              style: TextStyle(
                fontSize: size * 0.12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF002f6c),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class UMPLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create the main shield background
    final shieldPath = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    // Draw shield shape
    shieldPath.moveTo(center.dx, size.height * 0.1);
    shieldPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.15,
      size.width * 0.85,
      size.height * 0.4,
    );
    shieldPath.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.7,
      center.dx,
      size.height * 0.9,
    );
    shieldPath.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.7,
      size.width * 0.15,
      size.height * 0.4,
    );
    shieldPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.15,
      center.dx,
      size.height * 0.1,
    );

    // Draw blue border
    paint.color = const Color(0xFF002f6c);
    canvas.drawPath(shieldPath, paint);

    // Create inner shield
    final innerPath = Path();
    innerPath.moveTo(center.dx, size.height * 0.15);
    innerPath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.2,
      size.width * 0.8,
      size.height * 0.4,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.68,
      center.dx,
      size.height * 0.85,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.68,
      size.width * 0.2,
      size.height * 0.4,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      center.dx,
      size.height * 0.15,
    );

    // Draw white background
    paint.color = Colors.white;
    canvas.drawPath(innerPath, paint);

    // Draw the four quadrants representing the logo sections
    final quadrantSize = size.width * 0.25;
    final startX = center.dx - quadrantSize;
    final startY = center.dy - quadrantSize * 0.8;

    // Top-left quadrant (Yellow with sun rays)
    paint.color = const Color(0xFFffcc00);
    final sunRect = Rect.fromLTWH(startX, startY, quadrantSize, quadrantSize);
    canvas.drawArc(sunRect, 0, 6.28, true, paint);

    // Draw sun rays
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final startPoint = Offset(
        sunRect.center.dx + (quadrantSize * 0.2) * math.cos(angle),
        sunRect.center.dy + (quadrantSize * 0.2) * math.sin(angle),
      );
      final endPoint = Offset(
        sunRect.center.dx + (quadrantSize * 0.4) * math.cos(angle),
        sunRect.center.dy + (quadrantSize * 0.4) * math.sin(angle),
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }

    paint.style = PaintingStyle.fill;

    // Top-right quadrant (White with blue cross)
    paint.color = Colors.white;
    final crossRect = Rect.fromLTWH(
        startX + quadrantSize, startY, quadrantSize, quadrantSize);
    canvas.drawRect(crossRect, paint);

    // Draw blue cross
    paint.color = const Color(0xFF002f6c);
    final crossWidth = quadrantSize * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(
        crossRect.center.dx - crossWidth / 2,
        crossRect.top,
        crossWidth,
        quadrantSize,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        crossRect.left,
        crossRect.center.dy - crossWidth / 2,
        quadrantSize,
        crossWidth,
      ),
      paint,
    );

    // Bottom-left quadrant (Green with horizontal lines)
    paint.color = const Color(0xFF4CAF50);
    final greenRect = Rect.fromLTWH(
        startX, startY + quadrantSize, quadrantSize, quadrantSize);
    canvas.drawRect(greenRect, paint);

    // Draw horizontal lines
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    for (int i = 1; i < 4; i++) {
      final y = greenRect.top + (quadrantSize / 4) * i;
      canvas.drawLine(
        Offset(greenRect.left + quadrantSize * 0.1, y),
        Offset(greenRect.right - quadrantSize * 0.1, y),
        paint,
      );
    }

    paint.style = PaintingStyle.fill;

    // Bottom-right quadrant (Red)
    paint.color = const Color(0xFFE53935);
    final redRect = Rect.fromLTWH(startX + quadrantSize, startY + quadrantSize,
        quadrantSize, quadrantSize);
    canvas.drawRect(redRect, paint);

    // Draw white cross in center
    paint.color = Colors.white;
    final centerCrossWidth = size.width * 0.08;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - centerCrossWidth / 2,
        startY - centerCrossWidth / 2,
        centerCrossWidth,
        quadrantSize * 2 + centerCrossWidth,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        startX - centerCrossWidth / 2,
        center.dy - centerCrossWidth / 2,
        quadrantSize * 2 + centerCrossWidth,
        centerCrossWidth,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
