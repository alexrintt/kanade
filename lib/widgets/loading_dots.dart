import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

class DotLoadingIndicator extends StatefulWidget {
  const DotLoadingIndicator({
    super.key,
    this.color,
    this.dots = 8,
    this.padding = k1dp,
    this.strokeWidth = k1dp,
    this.outline = false,
    this.duration = const Duration(seconds: 1),
  });

  final Color? color;
  final int dots;
  final double padding;
  final double strokeWidth;
  final bool outline;
  final Duration duration;

  @override
  State<DotLoadingIndicator> createState() => _DotLoadingIndicatorState();
}

class _DotLoadingIndicatorState extends State<DotLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _createController();
  }

  void _createController() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}))
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant DotLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _controller.dispose();
      _controller = AnimationController(vsync: this, duration: widget.duration)
        ..addListener(() => setState(() {}))
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Color get _defaultDotColor => context.isDark
      ? context.textTheme.labelSmall!.color!
      : context.primaryColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DotLoadingIndicatorPainter(
        color: widget.color ?? _defaultDotColor,
        outline: widget.outline,
        padding: widget.padding,
        totalCount: widget.dots,
        currentCount:
            ((_controller.value * (1 + 1 / widget.dots)) * widget.dots).floor(),
        strokeWidth: widget.strokeWidth,
        progress: _controller.value,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class DotLoadingIndicatorPainter extends CustomPainter {
  const DotLoadingIndicatorPainter({
    required this.color,
    required this.totalCount,
    required this.currentCount,
    required this.padding,
    required this.strokeWidth,
    required this.outline,
    required this.progress,
  });

  final Color color;
  final int totalCount;
  final int currentCount;
  final double padding;
  final double strokeWidth;
  final bool outline;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    assert(totalCount >= 0);
    assert(currentCount <= totalCount);

    if (totalCount <= 0) return;

    final double blank = (totalCount - 1) * padding;

    final double dotSize = (size.width - blank - strokeWidth * 2) / totalCount;

    final double top = size.height / 2 - dotSize / 2;

    for (int i = 0; i < currentCount; i++) {
      final double left = i * dotSize + i * padding + strokeWidth;

      canvas.drawRect(
        Rect.fromLTWH(left, top, dotSize, dotSize),
        Paint()
          ..color = color.withOpacity((i + 1) / totalCount)
          ..style = (outline ? PaintingStyle.stroke : PaintingStyle.fill)
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(DotLoadingIndicatorPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.totalCount != totalCount ||
        oldDelegate.currentCount != currentCount ||
        oldDelegate.padding != padding ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.outline != outline ||
        oldDelegate.progress != progress;
  }
}
