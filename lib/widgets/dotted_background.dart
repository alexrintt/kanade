import 'package:flutter/material.dart';

class DottedBackground extends StatefulWidget {
  final Widget? child;
  final Color color;

  /// Size of each square pattern
  final double? size;

  /// double [between 0.0 and 0.1] that represents the fraction of each square padding
  /// 1 means full spacing, what renders no background, because 100% of the pattern is just padding
  /// 0 means no spacing, what render a solid background, because 100% of the pattern is only solid color
  /// Generally we can set as [0.9 or 0.8]
  final double? spacing;

  const DottedBackground({
    Key? key,
    this.child,
    required this.color,
    this.size,
    this.spacing,
  }) : super(key: key);

  @override
  _DottedBackgroundState createState() => _DottedBackgroundState();
}

class _DottedBackgroundState extends State<DottedBackground> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: DottedBackgroundPainter(
          color: widget.color,
          size: widget.size,
          spacing: widget.spacing,
        ),
        isComplex: false,
        child: widget.child,
        willChange: false,
      ),
    );
  }
}

class DottedBackgroundPainter extends CustomPainter {
  final Color color;
  final double? size;
  final double? spacing;

  const DottedBackgroundPainter({
    required this.color,
    required this.size,
    required this.spacing,
  });

  double get _size => size ?? 5.0;

  double get _spacing => 1 - (spacing ?? 0.85);

  @override
  void paint(Canvas canvas, Size size) {
    assert(_spacing >= 0.0 && _spacing <= 1.0);

    final paint = Paint()..color = color;

    final xCount = size.width ~/ _size + 1;
    final yCount = size.height ~/ _size + 1;

    final overflowX = size.width - xCount * _size;
    final overflowY = size.height - yCount * _size;

    for (var i = 0; i < xCount; i++) {
      for (var j = 0; j < yCount; j++) {
        final x = i * _size + overflowX / 2;
        final y = j * _size + overflowY / 2;

        final center = Rect.fromCenter(
          center: Offset(x + _size / 2, y + _size / 2),
          width: _size * _spacing,
          height: _size * _spacing,
        );

        canvas.drawRect(center, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DottedBackgroundPainter oldDelegate) => false;
}
