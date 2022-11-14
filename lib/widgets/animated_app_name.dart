import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:kanade/pages/settings_page.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/widgets/multi_animated_builder.dart';

class AnimatedAppName extends StatefulWidget {
  final Size? size;

  final Color? dimmedColor;
  final Color? highlightColor;
  final String? fontFamily;
  final String? text;

  const AnimatedAppName({
    Key? key,
    this.size,
    this.dimmedColor,
    this.highlightColor,
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

    _curve = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get defaultDimmedColor => context.theme.disabledColor;
  Color get defaultHighlightColor => context.primaryColor.withOpacity(.5);

  String get _text => widget.text ?? packageInfo.appName;

  @override
  Widget build(BuildContext context) {
    final textPainter = AnimatedAppNamePainter.createTextPainter(_text);

    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      child: MultiAnimatedBuilder(
        animations: [_controller, themeStore],
        builder: (context, child) {
          return CustomPaint(
            painter: AnimatedAppNamePainter(
              text: _text,
              fontFamily: widget.fontFamily,
              dimmedColor: widget.dimmedColor ?? defaultDimmedColor,
              highlightColor: widget.highlightColor ?? defaultHighlightColor,
              value: themeStore.currentThemeBrightness == Brightness.light
                  ? 0
                  : _curve.value,
            ),
            willChange: true,
            size: widget.size ?? Size(textPainter.width, textPainter.height),
          );
        },
      ),
    );
  }
}

class AnimatedAppNamePainter extends CustomPainter {
  final Color dimmedColor;
  final Color highlightColor;
  final double value;

  late TextPainter _textPainter;

  Offset _textOffsetFrom(Size size) =>
      Offset(0, size.height / 2 - _textPainter.size.height / 2);

  AnimatedAppNamePainter({
    required this.dimmedColor,
    required this.highlightColor,
    required this.value,
    required String text,
    String? fontFamily,
  }) {
    _textPainter = createTextPainter(
      text,
      fontFamily: fontFamily ?? 'Forward',
      color: dimmedColor,
    );
  }

  static TextPainter createTextPainter(
    String text, {
    String fontFamily = 'Forward',
    Color? color,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text.toUpperCase(),
        style: TextStyle(
          fontFamily: fontFamily,
          height: 2,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    final textOffset = _textOffsetFrom(size);

    final baseRadius = _textPainter.height;

    final sigma = _convertRadiusToSigma(baseRadius);

    // Times 2 to add a natural delay between each "highlight" effect.
    final radius = baseRadius + sigma * 2;

    // Sigma increases the "highlight" effect radius, so we need to consider it
    // when compututing our circle X position.
    final startX = textOffset.dx - radius;
    final finalX = startX + radius + _textPainter.width + radius;

    final progressX = startX + (finalX - startX) * value;

    _textPainter.paint(
      canvas,
      Offset.zero + textOffset,
    );

    canvas.drawCircle(
      Offset(progressX, textOffset.dy + _textPainter.height / 2),
      baseRadius,
      Paint()
        ..color = highlightColor
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          sigma,
        )
        ..blendMode = BlendMode.srcIn,
    );

    canvas.restore();
  }

  static double _convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  @override
  bool shouldRepaint(covariant AnimatedAppNamePainter oldDelegate) =>
      oldDelegate.dimmedColor != dimmedColor ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.value != value;
}
