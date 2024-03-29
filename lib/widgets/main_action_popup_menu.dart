import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/device_apps_store.dart';
import 'app_list_tile.dart';

class MainActionPopupMenu extends StatefulWidget {
  const MainActionPopupMenu({
    super.key,
    this.packageId,
    this.packageName,
    required this.subtitle,
    required this.title,
    required this.actionButtons,
    required this.icon,
    required this.tiles,
  });

  final Widget icon;

  final String? packageId;
  final String? packageName;
  final String subtitle;
  final String title;

  final List<Widget> actionButtons;
  final List<Widget> tiles;

  @override
  State<MainActionPopupMenu> createState() => _MainActionPopupMenu();
}

class _MainActionPopupMenu extends State<MainActionPopupMenu>
    with DeviceAppsStoreMixin {
  @override
  Widget build(BuildContext context) {
    return _buildScaffoldBody();
  }

  Widget _buildScaffoldBody() {
    const double kChipSpacing = k4dp;

    return Dialog(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.all(k4dp),
      surfaceTintColor: Colors.transparent,
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: kChipSpacing),
          AppListTile(
            contentPadding:
                const EdgeInsets.all(kChipSpacing).copyWith(bottom: 0),
            leading: widget.icon,
            title: Text(widget.title),
            subtitle: Text(widget.subtitle),
          ),
          const Divider(height: k1dp),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(kChipSpacing),
              child: Wrap(
                spacing: kChipSpacing,
                runSpacing: kChipSpacing,
                children: <Widget>[
                  ...widget.tiles,
                ],
              ),
            ),
          ),
          const Divider(height: k1dp),
          const SizedBox(height: kChipSpacing),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kChipSpacing),
              child: Wrap(
                spacing: kChipSpacing,
                runSpacing: kChipSpacing,
                children: <Widget>[
                  ...widget.actionButtons,
                ],
              ),
            ),
          ),
          const SizedBox(height: kChipSpacing),
          const SizedBox(height: kChipSpacing),
          const SizedBox(height: kChipSpacing),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.text,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String text;
  final String tooltip;
  final Widget icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget result = RawChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(right: k4dp),
      tooltip: tooltip,
      avatar: Transform.scale(
        scale: 0.7,
        child: icon,
      ),
      label: Text(
        text,
        style: context.textTheme.labelMedium,
      ),
    );

    if (!enabled) {
      result = Opacity(
        opacity: 0.5,
        child: AbsorbPointer(
          child: result,
        ),
      );
    }

    return result;
  }
}
