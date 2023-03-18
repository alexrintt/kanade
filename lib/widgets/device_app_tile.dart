import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/package_bytes.dart';
import '../utils/share_file.dart';
import 'app_list_tile.dart';

enum DeviceAppTileAction {
  uninstall,
  share,
  open,
  extract;
}

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
  bool get _hasIcon => widget.package.icon != null;

  Uint8List? get _icon => _hasIcon ? widget.package.icon! : null;

  bool get _isSelected => widget.isSelected;

  bool get _showAppIcons =>
      settingsStore.getBoolPreference(SettingsBoolPreference.displayAppIcons);

  Widget _buildTileTitle() {
    int? size;

    try {
      size = widget.package.size;
    } on AppIsNotAvailable {
      size = null;
    }

    return Text(
      '${widget.package.name} ${size != null ? size.formatBytes() : ''}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTileLeading() {
    return Center(
      child: _hasIcon
          ? Image.memory(
              _icon!,
              errorBuilder: (_, __, ___) =>
                  const Icon(AppIcons.apk, size: kDefaultIconSize),
            )
          : const Icon(AppIcons.apk, size: kDefaultIconSize),
    );
  }

  Widget _buildTileSubtitle() {
    return Text(
      widget.package.id!,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> perform(DeviceAppTileAction action, PackageInfo package) async {
    switch (action) {
      case DeviceAppTileAction.extract:
        if (package.id == null) return;
        await store.extractApk(package);
        break;
      case DeviceAppTileAction.uninstall:
        if (package.id == null) return;
        await DevicePackages.uninstallPackage(package.id!);
        break;
      case DeviceAppTileAction.share:
        if (package.installerPath == null) return;
        await shareFile(path: package.installerPath);
        break;
      case DeviceAppTileAction.open:
        if (package.id == null) return;
        await DevicePackages.openPackage(package.id!);
        break;
    }
  }

  Widget _buildPopupMenu() {
    return SimpleDialog(
      children: <Widget>[
        AppListTile(
          title: const Text('Open app'),
          leading: const Icon(AppIcons.externalLink, size: kDefaultIconSize),
          onTap: () {
            perform(DeviceAppTileAction.open, widget.package);
          },
        ),
        AppListTile(
          title: const Text('Share apk'),
          leading: const Icon(AppIcons.share, size: kDefaultIconSize),
          onTap: () {
            perform(DeviceAppTileAction.share, widget.package);
          },
        ),
        AppListTile(
          title: const Text('Extract apk'),
          leading: const Icon(AppIcons.download, size: kDefaultIconSize),
          onTap: () {
            perform(DeviceAppTileAction.extract, widget.package);
          },
        ),
        AppListTile(
          title: const Text('Uninstall'),
          leading: const Icon(
            AppIcons.delete,
            size: kDefaultIconSize,
            color: Colors.red,
          ),
          onTap: () {
            perform(DeviceAppTileAction.uninstall, widget.package);
          },
        ),
      ],
    );
  }

  Widget _buildAppListTile() {
    return AppListTile(
      onSelectionChange: (_) => store.toggleSelect(item: widget.package),
      popupMenuBuilder: (_) => _buildPopupMenu(),
      selected: _isSelected,
      leading: _showAppIcons ? _buildTileLeading() : null,
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
