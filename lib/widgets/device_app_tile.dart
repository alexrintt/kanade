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
    required this.subtitle,
    this.onPopupMenuTapped,
  });

  final PackageInfo package;
  final bool isSelected;
  final String subtitle;
  final bool showCheckbox;
  final VoidCallback onTap;
  final VoidCallback? onPopupMenuTapped;

  @override
  _DeviceAppTileState createState() => _DeviceAppTileState();
}

class _DeviceAppTileState extends State<DeviceAppTile>
    with ContextualMenuStoreMixin, DeviceAppsStoreMixin, SettingsStoreMixin {
  bool get _isSelected => widget.isSelected;

  Widget _buildTileTitle() {
    return Text(
      widget.package.nameWithFormattedSize,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTileSubtitle() {
    return Text(
      widget.subtitle,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAppListTile() {
    return AppListTile(
      onSelectionChange: (_) => store.toggleSelect(item: widget.package),
      selected: _isSelected,
      leading: Center(child: PackageImageBytes(icon: widget.package.icon)),
      isThreeLine: true,
      title: _buildTileTitle(),
      subtitle: _buildTileSubtitle(),
      inSelectionMode: widget.showCheckbox,
      onTap: widget.onTap,
      flat: false,
      onPopupMenuTapped: widget.onPopupMenuTapped,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildAppListTile();
  }
}
