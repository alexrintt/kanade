import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:share_plus/share_plus.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps_store.dart';
import '../stores/settings_store.dart';
import '../utils/package_bytes.dart';
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
              errorBuilder: (_, __, ___) => const Icon(Pixel.android),
            )
          : const Icon(Pixel.android),
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
        try {
          await Share.shareXFiles(<XFile>[XFile(package.installerPath!)]);
        } on PlatformException {
          // The user clicked twice too fast, which created 2 share requests and the second one failed.
          // Unhandled Exception: PlatformException(Share callback error, prior share-sheet did not call back, did you await it? Maybe use non-result variant, null, null).
          return;
        }
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
          leading: const Icon(Pixel.frame),
          onTap: () {
            perform(DeviceAppTileAction.open, widget.package);
          },
        ),
        AppListTile(
          title: const Text('Share apk'),
          leading: const Icon(Pixel.open),
          onTap: () {
            perform(DeviceAppTileAction.share, widget.package);
          },
        ),
        AppListTile(
          title: const Text('Extract apk'),
          leading: const Icon(Pixel.download),
          onTap: () {
            perform(DeviceAppTileAction.extract, widget.package);
          },
        ),
        AppListTile(
          title: const Text('Uninstall'),
          leading: const Icon(Pixel.trash, color: Colors.red),
          onTap: () {
            perform(DeviceAppTileAction.open, widget.package);
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
