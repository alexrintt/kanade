import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.iconSize,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback? onTap;
  final double? iconSize;

  @override
  AppIconButtonState createState() => AppIconButtonState();
}

class AppIconButtonState extends State<AppIconButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      onPressed: widget.onTap,
      splashColor: context.theme.splashColor,
      highlightColor: context.theme.highlightColor,
      icon: widget.icon,
      iconSize: widget.iconSize,
      tooltip: widget.tooltip,
    );
  }
}
