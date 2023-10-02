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
    this.leading,
    this.automaticallyImplyLeading = false,
    this.large = false,
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
  final bool large;

  @override
  State<SliverAppBarTranslucent> createState() =>
      _SliverAppBarTranslucentState();
}

class _SliverAppBarTranslucentState extends State<SliverAppBarTranslucent>
    with SettingsStoreMixin {
  @override
  Widget build(BuildContext context) {
    if (widget.large) {
      return SliverAppBar.large(
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        leading: widget.leading,
        titleSpacing: widget.titleSpacing ?? k10dp,
        scrolledUnderElevation: widget.scrolledUnderElevation,
        backgroundColor: widget.backgroundColor,
        elevation: widget.elevation,
        shadowColor: widget.shadowColor,
        surfaceTintColor: widget.surfaceTintColor,
        foregroundColor: widget.foregroundColor,
        title: widget.title,
        bottom: widget.bottom,
        actions: widget.actions,
        // Large implies this config:
        // floating: false,
        // pinned: true,
      );
    }

    return SliverAppBar(
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      leading: widget.leading,
      titleSpacing: widget.titleSpacing ?? k10dp,
      scrolledUnderElevation: widget.scrolledUnderElevation,
      backgroundColor: widget.backgroundColor,
      elevation: widget.elevation,
      shadowColor: widget.shadowColor,
      surfaceTintColor: widget.surfaceTintColor,
      foregroundColor: widget.foregroundColor,
      title: widget.title,
      bottom: widget.bottom,
      actions: widget.actions,
      floating: widget.floating,
      pinned: widget.pinned,
    );
  }
}
