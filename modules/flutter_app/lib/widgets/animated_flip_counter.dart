import 'package:flutter/material.dart';

class AnimatedCount extends ImplicitlyAnimatedWidget {
  const AnimatedCount({
    super.key,
    required this.count,
    super.duration = const Duration(milliseconds: 300),
    super.curve,
    this.textStyle,
  });

  final int count;
  final TextStyle? textStyle;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedCountState();
}

class _AnimatedCountState extends AnimatedWidgetBaseState<AnimatedCount> {
  IntTween? _count;

  @override
  Widget build(BuildContext context) {
    return Text(
      (_count?.evaluate(animation) ?? 0).toString(),
      style: widget.textStyle,
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _count = visitor(
      _count,
      widget.count,
      (dynamic value) => IntTween(begin: value as int),
    ) as IntTween?;
  }
}

class AnimatedCountBuilder extends ImplicitlyAnimatedWidget {
  const AnimatedCountBuilder({
    super.key,
    required this.count,
    required super.duration,
    super.curve,
    required this.builder,
  });

  final int count;
  final Widget Function(BuildContext, int) builder;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedCountBuilderState();
}

class _AnimatedCountBuilderState
    extends AnimatedWidgetBaseState<AnimatedCountBuilder> {
  IntTween? _count;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _count?.evaluate(animation) ?? 0);
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _count = visitor(
      _count,
      widget.count,
      (dynamic value) => IntTween(begin: value as int),
    ) as IntTween?;
  }
}
