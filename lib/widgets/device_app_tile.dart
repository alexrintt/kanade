import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps_store.dart';
import '../stores/settings_store.dart';
import 'app_list_tile.dart';
import 'image_uri.dart';

class DeviceAppTile extends StatefulWidget {
  const DeviceAppTile(
    this.package, {
    super.key,
    required this.isSelected,
    required this.showCheckbox,
    required this.onTap,
    required this.onPopupMenuTapped,
  });

  final PackageInfo package;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback onTap;
  final VoidCallback onPopupMenuTapped;

  @override
  _DeviceAppTileState createState() => _DeviceAppTileState();
}

class _DeviceAppTileState extends State<DeviceAppTile>
    with ContextualMenuStoreMixin, DeviceAppsStoreMixin, SettingsStoreMixin {
  bool get _isSelected => widget.isSelected;

  bool get _showAppIcons =>
      settingsStore.getBoolPreference(SettingsBoolPreference.displayAppIcons);

  Widget _buildTileTitle() {
    return Text(
      widget.package.nameWithFormattedSize,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTileSubtitle() {
    return Text(
      widget.package.id!,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAppListTile() {
    return AppListTile(
      onSelectionChange: (_) => store.toggleSelect(item: widget.package),
      onPopupMenuTapped: widget.onPopupMenuTapped,
      selected: _isSelected,
      leading:
          _showAppIcons ? PackageImageBytes(icon: widget.package.icon) : null,
      title: _buildTileTitle(),
      subtitle: _buildTileSubtitle(),
      inSelectionMode: widget.showCheckbox,
      onTap: widget.onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildAppListTile();
  }
}
