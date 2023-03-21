import 'dart:ui';

import 'package:flutter/material.dart' hide SliverAppBar;
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/settings_store.dart';
import '../widgets/sliver_app_bar.dart';

class SliverAppBarTranslucent extends StatefulWidget {
  const SliverAppBarTranslucent({
    super.key,
    this.backgroundColor,
    this.floating = true,
    this.pinned = false,
    this.bottom,
    this.actions,
    this.scrolledUnderElevation,
    this.titleSpacing,
    this.elevation,
    this.title,
    this.shadowColor,
    this.surfaceTintColor,
    this.foregroundColor,
    this.translucentBorderWidth = 2,
    this.translucentBlurSigma = 4,
    this.translucentBackgroundColor,
    this.leading,
    this.automaticallyImplyLeading = false,
  });

  final Color? backgroundColor;
  final bool floating;
  final bool pinned;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final double? scrolledUnderElevation;
  final double? titleSpacing;
  final double? elevation;
  final Widget? title;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Color? foregroundColor;
  final double translucentBorderWidth;
  final double translucentBlurSigma;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// Default to transparent. The background color of the app bar when the app bar
  /// is translucent, the alpha channel will be ignored.
  final Color? translucentBackgroundColor;

  @override
  State<SliverAppBarTranslucent> createState() =>
      _SliverAppBarTranslucentState();
}

class _SliverAppBarTranslucentState extends State<SliverAppBarTranslucent>
    with SettingsStoreMixin {
  Color get _translucentBackgroundColor =>
      widget.translucentBackgroundColor ?? Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsStore,
      builder: (BuildContext context, Widget? child) => SliverAppBar(
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        leading: widget.leading,
        wrapperBuilder: (BuildContext context, Widget appBar) {
          if (settingsStore.transparentNavigationBar) {
            return Container(
              decoration: BoxDecoration(
                color: _translucentBackgroundColor == Colors.transparent
                    ? null
                    : _translucentBackgroundColor.withOpacity(.4),
                border: Border(
                  bottom: BorderSide(
                    color: context.primaryColor,
                    width: widget.translucentBorderWidth,
                  ),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.translucentBlurSigma,
                    sigmaY: widget.translucentBlurSigma,
                  ),
                  child: appBar,
                ),
              ),
            );
          }
          return appBar;
        },
        titleSpacing: widget.titleSpacing ?? k10dp,
        scrolledUnderElevation: settingsStore.transparentNavigationBar
            ? 0.0
            : widget.scrolledUnderElevation,
        backgroundColor: settingsStore.transparentNavigationBar
            ? Colors.transparent
            : widget.backgroundColor,
        elevation:
            settingsStore.transparentNavigationBar ? 0.0 : widget.elevation,
        shadowColor: settingsStore.transparentNavigationBar
            ? Colors.transparent
            : widget.shadowColor,
        surfaceTintColor: settingsStore.transparentNavigationBar
            ? Colors.transparent
            : widget.surfaceTintColor,
        foregroundColor: settingsStore.transparentNavigationBar
            ? Colors.transparent
            : widget.foregroundColor,
        title: widget.title,
        bottom: widget.bottom,
        actions: widget.actions,
        floating: widget.floating,
        pinned: widget.pinned,
      ),
    );
  }
}
