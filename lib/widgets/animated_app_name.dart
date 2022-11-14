import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:kanade/pages/settings_page.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/widgets/multi_animated_builder.dart';

class AnimatedAppName extends StatefulWidget {
  final Size? size;

  final Color? dimmedColor;
  final Color? highlightColor;
  final Color? backgroundColor;
  final String? fontFamily;
  final String? text;

  const AnimatedAppName({
    Key? key,
    this.size,
    this.dimmedColor,
    this.highlightColor,
    this.backgroundColor,
    this.fontFamily,
    this.text,
  }) : super(key: key);

  @override
  State<AnimatedAppName> createState() => _AnimatedAppNameState();
}

class _AnimatedAppNameState extends State<AnimatedAppName>
    with SingleTickerProviderStateMixin, ThemeStoreMixin {
  late AnimationController _controller;
  late Animation<double> _curve;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 5,
      ),
    )..repeat();

    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutSine);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get defaultBackgroundColor =>
      context.theme.appBarTheme.backgroundColor!;
  Color get defaultDimmedColor => context.theme.disabledColor;
  Color get defaultHighlightColor =>
      themeStore.currentThemeBrightness == Brightness.light
          ? Colors.transparent
          : context.theme.primaryColor.withOpacity(.25);

  @override
  Widget build(BuildContext context) {
    final text = widget.text ?? packageInfo.appName;

    final textPainter = AnimatedAppNameLetterPainter.createTextPainter(text);

    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      child: MultiAnimatedBuilder(
        animations: [_controller, themeStore],
        builder: (context, child) {
          return CustomPaint(
            painter: AnimatedAppNameLightPainter(
              text: text,
              fontFamily: widget.fontFamily,
              dimmedColor: widget.dimmedColor ?? defaultDimmedColor,
              highlightColor: widget.highlightColor ?? defaultHighlightColor,
              backgroundColor: widget.backgroundColor ?? defaultBackgroundColor,
              value: _curve.value,
            ),
            foregroundPainter: AnimatedAppNameLetterPainter(
              dimmedColor: widget.dimmedColor ?? defaultDimmedColor,
              highlightColor: widget.highlightColor ?? defaultHighlightColor,
              backgroundColor: widget.backgroundColor ?? defaultBackgroundColor,
              text: packageInfo.appName,
            ),
            willChange: true,
            size: widget.size ?? Size(textPainter.width, textPainter.height),
          );
        },
      ),
    );
  }
}

class AnimatedAppNameLightPainter extends CustomPainter {
  final Color dimmedColor;
  final Color highlightColor;
  final Color backgroundColor;
  final double value;

  late TextPainter _textPainter;

  Offset _textOffsetFrom(Size size) =>
      Offset(0, size.height / 2 - _textPainter.size.height / 2);

  AnimatedAppNameLightPainter({
    required this.dimmedColor,
    required this.highlightColor,
    required this.backgroundColor,
    required this.value,
    required String text,
    String? fontFamily,
  }) {
    _textPainter = AnimatedAppNameLetterPainter.createTextPainter(
      text,
      fontFamily: fontFamily ?? 'Forward',
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final textOffset = _textOffsetFrom(size);

    final startX = textOffset.dx - _textPainter.width;
    final finalX = textOffset.dx + _textPainter.width * 2;

    final startY = textOffset.dx + _textPainter.height * 2;
    final finalY = textOffset.dx - _textPainter.height * 2;

    final clipRect = Rect.fromLTWH(
      textOffset.dx,
      textOffset.dy,
      _textPainter.width,
      _textPainter.height,
    );

    final backgroundRect = Rect.fromLTWH(
      textOffset.dx,
      textOffset.dy,
      finalX - startX,
      _textPainter.height,
    );

    canvas.clipRect(clipRect);
    canvas.drawRect(backgroundRect, Paint()..color = dimmedColor);

    final radius = _textPainter.height;

    final progressX = startX + (finalX - startX) * value;
    final progressY = startY - (finalY - startY).abs() * value;

    canvas.drawCircle(
      Offset(progressX, progressY),
      radius,
      Paint()
        ..color = highlightColor
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          _convertRadiusToSigma(radius),
        ),
    );
  }

  static double _convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  @override
  bool shouldRepaint(covariant AnimatedAppNameLightPainter oldDelegate) => true;
}

class AnimatedAppNameLetterPainter extends CustomPainter {
  final Color dimmedColor;
  final Color highlightColor;
  final Color backgroundColor;

  late TextPainter _textPainter;

  Offset _textOffsetFrom(Size size) =>
      Offset(0, size.height / 2 - _textPainter.size.height / 2);

  AnimatedAppNameLetterPainter({
    required this.dimmedColor,
    required this.highlightColor,
    required this.backgroundColor,
    required String text,
    String fontFamily = 'Forward',
  }) {
    _textPainter = createTextPainter(text, fontFamily: fontFamily);
  }

  static TextPainter createTextPainter(
    String text, {
    String fontFamily = 'Forward',
  }) {
    return TextPainter(
      text: TextSpan(
        text: text.toUpperCase(),
        style: TextStyle(
          fontFamily: fontFamily,
          height: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    final textOffset = _textOffsetFrom(size);

    _textPainter.paint(
      canvas,
      Offset.zero + textOffset,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        textOffset.dx,
        textOffset.dy,
        _textPainter.size.width,
        _textPainter.size.height,
      ),
      Paint()
        ..blendMode = BlendMode.srcOut
        ..color = backgroundColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnimatedAppNameLetterPainter oldDelegate) =>
      true;
}
