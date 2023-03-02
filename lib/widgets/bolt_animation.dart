import 'dart:math';
import 'dart:ui' as ui;

import 'package:fast_noise/fast_noise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

class BoltAnimation extends StatefulWidget {
  const BoltAnimation({super.key, required this.animate});

  final bool animate;

  @override
  State<BoltAnimation> createState() => _BoltAnimationState();
}

double random(double min, double max) {
  final Random random = Random();

  return random.nextDouble() * (max - min).abs() + min;
}

class _BoltAnimationState extends State<BoltAnimation>
    with TickerProviderStateMixin {
  late List<double> seeds;
  late List<double> timers;
  late List<double> velocities;
  late List<double> offsets;

  late AnimationController controller;

  late double randomBoltFactor;
  late double boltStrength;
  double get boltFragmentWidth => 100;
  late double amplitudeFactor;
  late double additionalStrength;

  double get _strength => boltStrength / _maxStrength;

  final double _maxStrength = 8;
  final double _minStrength = 0;

  @override
  void initState() {
    super.initState();

    _generateBoldConfig();
    startController();
  }

  bool get _running => _strength > 0;

  void _onStartPressing() {
    _generateBoldConfig(strength: random(_minStrength, _maxStrength));
  }

  void _onStopPressing() {
    _generateBoldConfig(strength: _minStrength);
  }

  @override
  void didUpdateWidget(covariant BoltAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _onStartPressing();
      } else {
        _onStopPressing();
      }
    }
  }

  void _generateBoldConfig({double? strength}) {
    randomBoltFactor = 0.1;
    boltStrength = strength ?? _minStrength;
    // boltFragmentWidth = 30;
    amplitudeFactor = 1;
    additionalStrength = 0;

    boltStrength = boltStrength.clamp(_minStrength, _maxStrength);

    seeds = List<double>.generate(boltStrength.ceil(), (_) => random(1e2, 1e6));
    timers = List<double>.generate(boltStrength.ceil(), (_) => random(1, 4));
    velocities = List<double>.generate(
      boltStrength.ceil(),
      (_) => ((random(1, 10)).floor() / 1e4) * (random(0, 10) >= 5 ? -1 : 1),
    );
    offsets = List<double>.generate(boltStrength.ceil(), (_) => 0);
  }

  void startController() {
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(
            () {
              seeds = <double>[
                for (int i = 0; i < seeds.length; i++) seeds[i] + velocities[i]
              ];
              offsets = <double>[
                for (int i = 0; i < offsets.length; i++)
                  offsets[i] + velocities[i] * (noise(seeds[i]) >= 0.5 ? 1 : -1)
              ];
              setState(() {});
            },
          )
          ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.dispose();
    startController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _onStartPressing();
        pressing = true;
      },
      onTapUp: (_) {
        pressing = false;
        _onStopPressing();
      },
      onTapCancel: () {
        pressing = false;
        _onStopPressing();
      },
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        willChange: true,
        isComplex: true,
        foregroundPainter: _running
            ? _BoltAnimationLight(
                color: context.primaryColor,
                lightness: _strength,
              )
            : _NoPainter(),
        painter: _running
            ? _BoltAnimationPainter(
                seeds: seeds,
                timers: timers,
                velocities: velocities.map((double e) => 0.0).toList(),
                offsets: offsets,
                color: context.primaryColor,
                amplitudeFactor: amplitudeFactor * _strength,
                boltFragmentWidth: random(10, 100),
                strength: _strength,
                boltStrength: boltStrength.ceil(),
                randomBoltFactor: randomBoltFactor,
                additionalStrength: additionalStrength,
              )
            : _NoPainter(),
        child: SizedBox(
          width: double.infinity,
          child: Opacity(
            opacity: _running ? 1 : 0.5,
            child:
                Image.asset('assets/images/bottom.png', height: kToolbarHeight),
          ),
        ),
      ),
    );
  }
}

double noise(double x, [double? y]) => PerlinNoise().getPerlin2(x, y ?? x);

const double k2pi = pi * 2;

class _NoPainter extends CustomPainter {
  @override
  void paint(ui.Canvas canvas, ui.Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BoltAnimationLight extends CustomPainter {
  const _BoltAnimationLight({required this.color, required this.lightness});

  final Color color;
  final double lightness;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    const double blur = 100;

    canvas.drawShadow(
      Path()
        ..addRect(Rect.fromLTWH(0, 0 - blur / 1.25, size.width, size.height)),
      color.withOpacity(random(0, 0.5)),
      blur,
      false,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BoltAnimationPainter extends CustomPainter {
  const _BoltAnimationPainter({
    required this.seeds,
    required this.timers,
    required this.velocities,
    required this.offsets,
    required this.color,
    required this.amplitudeFactor,
    required this.boltFragmentWidth,
    required this.randomBoltFactor,
    required this.boltStrength,
    required this.additionalStrength,
    required this.strength,
  });

  final double additionalStrength;
  final double strength;
  final int boltStrength;
  final List<double> seeds;
  final double boltFragmentWidth;
  final List<double> timers;
  final List<double> velocities;
  final List<double> offsets;
  final Color color;
  final double amplitudeFactor;
  final double randomBoltFactor;

  void drawBoltLines(
    double seed, {
    required Canvas canvas,
    required double width,
    required double height,
    required int i,
    required double start,
    required double end,
    required Color waveColor,
    double? alpha,
    required double trickness,
    required double offset,
  }) {
    final double amplitude = amplitudeFactor;
    final double centerY = height / 2;

    final double targetAmplitude = amplitude * centerY;

    Color c = waveColor;
    if (alpha != null) c = c.withAlpha((alpha * 255) ~/ 1);

    final List<Offset> positions = <Offset>[];

    final double rest =
        ((width / boltFragmentWidth).ceilToDouble() * boltFragmentWidth) -
            width;

    for (double x = width * start - rest / 2;
        x < width * end + rest;
        x += boltFragmentWidth) {
      final double edgeApprox = noise(seed, pow(seed, 3) / 1);

      final double anglePosition = (offset % 1) * k2pi;

      final double angle =
          ((((x / width) * k2pi + anglePosition) % k2pi) * 4) % k2pi;

      final double randomY = noise(pow(seed, 2) + x, pow(seed, 3) + x) *
          (height * noise(seed / 10, 1));

      final double deltaY = map(
            sin(noise(seeds[i]) * angle) * -1,
            -1,
            1,
            -targetAmplitude + randomY,
            targetAmplitude - randomY,
          ) *
          edgeApprox;

      final double y = centerY + deltaY;

      final double randomX =
          noise(seed + x, pow(seed, 2) + x) * (width * randomBoltFactor);

      positions.add(Offset(x + randomX / 4, y + randomY));
    }

    final Path path = Path();
    final Path shadowpath = Path();

    path.addPolygon(positions, false);

    shadowpath.addRect(Rect.fromLTWH(0, 0, width, height));

    shadowpath.lineTo(
      positions[positions.length - 1].dx,
      positions[positions.length - 1].dy,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = trickness * 2
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..strokeMiterLimit = 0
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < boltStrength; i++) {
      final double p = (i + 1) / boltStrength;
      // final double rp = 1 - p;
      drawBoltLines(
        seeds[i],
        i: i,
        canvas: canvas,
        start: 0,
        width: size.width,
        height: size.height,
        end: 1,
        offset: offsets[i],
        waveColor: color,
        alpha: p,
        trickness: p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

double map(double value, double a, double b, double c, double d) {
  return c + (value - a) / (b - a) * (d - c);
}
