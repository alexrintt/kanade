import 'dart:io';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/package_bytes.dart';
import '../utils/share_file.dart';
import 'app_icon_button.dart';
import 'app_list_tile.dart';
import 'image_uri.dart';
import 'package_menu_bottom_sheet.dart';
import 'toast.dart';

class DeviceAppTile extends StatefulWidget {
  const DeviceAppTile(
    this.package, {
    super.key,
    required this.isSelected,
    required this.showCheckbox,
    required this.onTap,
  });

  final PackageInfo package;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback onTap;

  @override
  _DeviceAppTileState createState() => _DeviceAppTileState();
}

class _DeviceAppTileState extends State<DeviceAppTile>
    with ContextualMenuStoreMixin, DeviceAppsStoreMixin, SettingsStoreMixin {
  bool get _isSelected => widget.isSelected;

  bool get _showAppIcons =>
      settingsStore.getBoolPreference(SettingsBoolPreference.displayAppIcons);

  String get _title {
    int? size;

    try {
      size = widget.package.size;
    } on AppIsNotAvailable {
      size = null;
    }

    return '${widget.package.name} ${size != null ? size.formatBytes() : ''}';
  }

  Widget _buildTileTitle() {
    return Text(
      _title,
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
      popupMenuBuilder: (_) => BottomSheetWithAnimationController(
        child: InstalledAppMenuOptions(
          iconBytes: widget.package.icon,
          packageId: widget.package.id,
          packageInstallerFile: widget.package.installerPath != null
              ? File(widget.package.installerPath!)
              : null,
          packageName: _title,
        ),
      ),
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
