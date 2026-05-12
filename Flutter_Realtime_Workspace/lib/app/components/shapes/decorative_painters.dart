import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
//  Realtime Workspace — Decorative Painters
//  Ambient accent shapes specific to a modern
//  collaboration and productivity dashboard.
// ═══════════════════════════════════════════════

/// Node-graph fragment — a handful of scattered dots connected
/// by thin quadratic-bezier arcs. Evokes team topology and
/// collaboration graphs. Keep [color] opacity low (≈ 0.12).
class TNetworkArcsPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final int seed;
  final int nodeCount;

  TNetworkArcsPainter({
    required this.color,
    this.isDark = true,
    this.seed = 11,
    this.nodeCount = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final w = size.width;
    final h = size.height;

    final nodes = List.generate(
      nodeCount,
      (_) => Offset(rng.nextDouble() * w, rng.nextDouble() * h),
    );

    final linePaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.07 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.15 : 0.10)
      ..style = PaintingStyle.fill;

    // Connect a sparse set of node pairs with gentle arcs
    final connections = [
      [0, 2], [1, 4], [2, 5], [0, 3], [3, 5],
    ];
    for (final pair in connections) {
      if (pair[0] >= nodeCount || pair[1] >= nodeCount) continue;
      final a = nodes[pair[0]];
      final b = nodes[pair[1]];
      final mid = (a + b) / 2;
      final ctrl = Offset(
        mid.dx + (rng.nextDouble() - 0.5) * 55,
        mid.dy - 18 - rng.nextDouble() * 38,
      );
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy),
        linePaint,
      );
    }

    for (final node in nodes) {
      canvas.drawCircle(node, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(TNetworkArcsPainter old) =>
      color != old.color ||
      isDark != old.isDark ||
      seed != old.seed ||
      nodeCount != old.nodeCount;
}

/// Broadcast rings — concentric partial-circle arcs radiating
/// from one corner. Suggests a live / realtime presence signal.
class TBroadcastRingsPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final int ringCount;
  final CornerPosition corner;

  TBroadcastRingsPainter({
    required this.color,
    this.isDark = true,
    this.ringCount = 4,
    this.corner = CornerPosition.topLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    late Offset origin;
    switch (corner) {
      case CornerPosition.topLeft:
        origin = Offset.zero;
      case CornerPosition.topRight:
        origin = Offset(size.width, 0);
      case CornerPosition.bottomLeft:
        origin = Offset(0, size.height);
      case CornerPosition.bottomRight:
        origin = Offset(size.width, size.height);
    }

    for (int i = 1; i <= ringCount; i++) {
      final radius = size.width * 0.16 * i;
      final paint = Paint()
        ..color = color.withValues(alpha: (isDark ? 0.09 : 0.065) / i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawCircle(origin, radius, paint);
    }
  }

  @override
  bool shouldRepaint(TBroadcastRingsPainter old) =>
      color != old.color ||
      isDark != old.isDark ||
      ringCount != old.ringCount ||
      corner != old.corner;
}

/// Data-stream lines — stacked horizontal paths with a gentle
/// sinusoidal drift. Suggests realtime data flowing through
/// channels. Pair with low-opacity colors.
class TDataFlowPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final int lineCount;
  final double phase;

  TDataFlowPainter({
    required this.color,
    this.isDark = true,
    this.lineCount = 5,
    this.phase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final spacing = h / (lineCount + 1);

    for (int i = 1; i <= lineCount; i++) {
      final baseY = spacing * i;
      final amplitude = 3.5 + i * 1.4;
      final frequency = 0.007 + i * 0.002;
      final alpha =
          (isDark ? 0.055 : 0.038) * (1 - (i / (lineCount + 1)) * 0.35);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;

      final path = Path()..moveTo(0, baseY);
      for (double x = 0; x <= w; x += 2) {
        path.lineTo(
          x,
          baseY + math.sin((x * frequency) + phase + i * 1.1) * amplitude,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(TDataFlowPainter old) =>
      color != old.color ||
      isDark != old.isDark ||
      lineCount != old.lineCount ||
      phase != old.phase;
}

/// Corner gradient arc — a curved accent in one corner.
/// Typically placed top-right or bottom-left.
class TCornerArcPainter extends CustomPainter {
  final Color color;
  final double radius;
  final CornerPosition corner;

  TCornerArcPainter({
    required this.color,
    this.radius = 200,
    this.corner = CornerPosition.topRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset center;
    switch (corner) {
      case CornerPosition.topLeft:
        center = Offset.zero;
      case CornerPosition.topRight:
        center = Offset(size.width, 0);
      case CornerPosition.bottomLeft:
        center = Offset(0, size.height);
      case CornerPosition.bottomRight:
        center = Offset(size.width, size.height);
    }

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(TCornerArcPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      corner != oldDelegate.corner;
}

enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Noise-grain texture overlay for a premium matte finish.
/// Apply over gradients for added depth.
class SGrainPainter extends CustomPainter {
  final double opacity;
  final int density;

  SGrainPainter({this.opacity = 0.03, this.density = 3000});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(12345);
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);

    for (int i = 0; i < density; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(SGrainPainter oldDelegate) =>
      opacity != oldDelegate.opacity || density != oldDelegate.density;
}
