import 'package:flutter/material.dart';

class Keep extends StatefulWidget {
  const Keep({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  _KeepState createState() => _KeepState();
}

class _KeepState extends State<Keep> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
