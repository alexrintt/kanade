import 'dart:typed_data';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:share_plus/share_plus.dart';

import '../stores/contextual_menu.dart';
import '../stores/device_apps.dart';
import '../utils/app_localization_strings.dart';
import '../utils/package_bytes.dart';
import 'app_icon_button.dart';

enum PackageTileActions {
  uninstall,
  share;

  Future<void> perform(Application package) async {
    switch (this) {
      case PackageTileActions.uninstall:
        await package.uninstallApp();
        break;
      case PackageTileActions.share:
        await Share.shareXFiles(<XFile>[XFile(package.apkFilePath)]);
        break;
    }
  }
}

class PackageTile extends StatefulWidget {
  const PackageTile(
    this.package, {
    super.key,
    required this.isSelected,
    required this.showCheckbox,
    required this.onPressed,
    required this.onLongPress,
  });

  final Application package;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  @override
  _PackageTileState createState() => _PackageTileState();
}

class _PackageTileState extends State<PackageTile>
    with
        ContextualMenuStoreMixin<PackageTile>,
        DeviceAppsStoreMixin<PackageTile> {
  static const Size _kLeadingSize = Size.square(50);

  bool get _hasIcon => widget.package is ApplicationWithIcon;

  Uint8List? get _icon =>
      _hasIcon ? (widget.package as ApplicationWithIcon).icon : null;

  bool get _isSelected => widget.isSelected;

  Widget? _buildTrailing() {
    Widget? child;

    if (widget.showCheckbox) {
      child = AppIconButton(
        onTap: () => store.toggleSelect(widget.package),
        tooltip: context.strings.toggleSelect,
        icon: Icon(
          _isSelected ? Pixel.checkbox : Pixel.checkboxon,
        ),
      );
    } else if (!_isSelected) {
      child = PopupMenuButton<PackageTileActions>(
        icon: const Icon(Pixel.morevertical),
        // TODO: Missing translation.
        tooltip: 'See more options',
        itemBuilder: (_) {
          return <PopupMenuEntry<PackageTileActions>>[
            const PopupMenuItem<PackageTileActions>(
              value: PackageTileActions.share,
              child: ListTile(
                leading: Icon(Pixel.forward),
                dense: true,
                // TODO: Missing translation.
                title: Text('Share apk'),
              ),
            ),
            const PopupMenuItem<PackageTileActions>(
              value: PackageTileActions.uninstall,
              child: ListTile(
                leading: Icon(Pixel.trash, color: Colors.red),
                dense: true,
                // TODO: Missing translation.
                title: Text('Uninstall'),
              ),
            ),
          ];
        },
        onSelected: (PackageTileActions? value) {
          if (value != null) {
            value.perform(widget.package);
          }
        },
      );
    }

    return SizedBox(
      width: _kLeadingSize.width,
      height: _kLeadingSize.height,
      child: child,
    );
  }

  Widget _buildTileTitle() {
    return Text(
      '${widget.package.appName} ${widget.package.size.formatBytes()}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTileLeading() {
    return SizedBox(
      width: _kLeadingSize.width,
      height: _kLeadingSize.height,
      child: Center(
        child: _hasIcon
            ? Image.memory(_icon!, gaplessPlayback: true)
            : const Icon(Pixel.android),
      ),
    );
  }

  Widget _buildTileSubtitle() {
    return Text(
      widget.package.packageName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildListTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: k5dp,
        horizontal: k8dp,
      ),
      trailing: _buildTrailing(),
      selected: _isSelected,
      selectedTileColor: context.theme.cardColor,
      dense: false,
      enableFeedback: false,
      visualDensity: VisualDensity.compact,
      leading: _buildTileLeading(),
      title: _buildTileTitle(),
      subtitle: _buildTileSubtitle(),
    );
  }

  Widget _buildInkEffectWrapper() {
    return InkWell(
      splashFactory: InkSplash.splashFactory,
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: DecoratedBox(
        decoration: _createBoxDecoration(),
        child: _buildListTile(),
      ),
    );
  }

  BoxDecoration _createBoxDecoration() {
    return BoxDecoration(
      color: _isSelected ? context.theme.splashColor : Colors.transparent,
      border: Border(
        left: BorderSide(
          color: _isSelected ? context.primaryColor : Colors.transparent,
          width: k2dp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        border: Border(
          bottom: BorderSide(color: context.theme.colorScheme.background),
        ),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(0),
        color: Colors.transparent,
        child: _buildInkEffectWrapper(),
      ),
    );
  }
}
