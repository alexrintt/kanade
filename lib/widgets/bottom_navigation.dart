import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixel.dart';

import '../stores/theme.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({
    super.key,
    required this.onChange,
    required this.index,
  }) : assert(index >= 0 && index < 4);

  final void Function(int) onChange;
  final int index;

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  @override
  void initState() {
    super.initState();
  }

  void _select(int index) {
    widget.onChange(index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: kToolbarHeight * 1.25,
        width: context.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            BottomNavigationItem(
              icon: Pixel.home,
              label: 'Home',
              selected: widget.index == 0,
              onTap: () => _select(0),
            ),
            BottomNavigationItem(
              icon: Pixel.android,
              label: 'Apks',
              selected: widget.index == 1,
              onTap: () => _select(1),
            ),
            BottomNavigationItem(
              // icon: Pixel.arrowbardown,
              label: 'Extracting',
              selected: widget.index == 2,
              onTap: () => _select(2),
              icon: Pixel.download,
              // child: Icon(Pixel.flatten),
            ),
            BottomNavigationItem(
              icon: Pixel.folder,
              label: 'Explorer',
              selected: widget.index == 3,
              onTap: () => _select(3),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavigationItem extends StatefulWidget {
  const BottomNavigationItem({
    super.key,
    this.icon,
    this.child,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : assert(child != null || icon != null);

  final IconData? icon;
  final Widget? child;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<BottomNavigationItem> createState() => _BottomNavigationItemState();
}

class _BottomNavigationItemState extends State<BottomNavigationItem>
    with ThemeStoreMixin<BottomNavigationItem> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        child: ColoredBox(
          color: Colors.transparent,
          child: Opacity(
            opacity: widget.selected ? 1 : 0.75,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: const EdgeInsets.symmetric(
                        horizontal: k10dp,
                        vertical: k1dp,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(k10dp),
                        color: widget.selected
                            ? themeStore.currentThemeBrightness.isDark
                                ? context.dividerColor
                                : context.primaryColor.withOpacity(.2)
                            : null,
                      ),
                      child: widget.child ??
                          Icon(
                            widget.icon,
                            color: context.primaryColor,
                          ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: k5dp),
                  child: Text(
                    widget.label,
                    style: TextStyle(color: context.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
