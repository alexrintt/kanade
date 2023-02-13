import 'package:flutter/material.dart';

/// Creates a widget that rebuilds when the given list of [animations] changes.
///
/// The [animations] argument is required.
class MultiAnimatedBuilder extends StatefulWidget {
  const MultiAnimatedBuilder({
    super.key,
    required this.animations,
    required this.builder,
    this.child,
  });

  final Widget Function(BuildContext, Widget?) builder;
  final List<Listenable> animations;
  final Widget? child;

  @override
  State<MultiAnimatedBuilder> createState() => _AnimatedState();
}

class _AnimatedState extends State<MultiAnimatedBuilder> {
  void _attachAll(List<Listenable> animations, VoidCallback listener) {
    for (final Listenable animation in animations) {
      animation.addListener(listener);
    }
  }

  void _detachAll(List<Listenable> animations, VoidCallback listener) {
    for (final Listenable animation in animations) {
      animation.removeListener(listener);
    }
  }

  @override
  void initState() {
    super.initState();

    _attachAll(widget.animations, _handleChange);
  }

  @override
  void didUpdateWidget(MultiAnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    _detachAll(oldWidget.animations, _handleChange);
    _attachAll(widget.animations, _handleChange);
  }

  @override
  void dispose() {
    _detachAll(widget.animations, _handleChange);

    super.dispose();
  }

  void _handleChange() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}
