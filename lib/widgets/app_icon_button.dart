import 'package:flutter/material.dart';

class AppIconButton extends StatefulWidget {
  final String tooltip;
  final Widget icon;
  final VoidCallback onTap;

  const AppIconButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  }) : super(key: key);

  @override
  AppIconButtonState createState() => AppIconButtonState();
}

class AppIconButtonState extends State<AppIconButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onTap,
      splashColor: Colors.white.withOpacity(.05),
      highlightColor: Colors.white.withOpacity(.05),
      icon: widget.icon,
      tooltip: widget.tooltip,
    );
  }
}
