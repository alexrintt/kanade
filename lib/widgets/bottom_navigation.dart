import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixel.dart';

import '../stores/theme.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({
    super.key,
    required this.onChange,
    required this.index,
  }) : assert(index >= 0 && index < 2);

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
            // BottomNavigationItem(
            //   icon: Pixel.folder,
            //   label: 'Explorer',
            //   selected: widget.index == 2,
            //   onTap: () => _select(2),
            // ),
          ],
        ),
      ),
    );
  }
}

class BottomNavigationItem extends StatefulWidget {
  const BottomNavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.symmetric(
                    horizontal: k10dp,
                    vertical: k1dp,
                  ),
                  margin: const EdgeInsets.only(bottom: k2dp),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(k10dp),
                    color: widget.selected
                        ? themeStore.currentThemeBrightness.isDark
                            ? context.dividerColor
                            : context.primaryColor.withOpacity(.2)
                        : null,
                  ),
                  child: Icon(
                    widget.icon,
                    color: context.primaryColor,
                  ),
                ),
                Text(
                  widget.label,
                  style: TextStyle(color: context.primaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
