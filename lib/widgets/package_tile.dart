import 'dart:typed_data';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:pixelarticons/pixel.dart';

import 'app_icon_button.dart';

class PackageTile extends StatefulWidget {
  final Application package;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  const PackageTile(
    this.package, {
    Key? key,
    required this.isSelected,
    required this.showCheckbox,
    required this.onPressed,
    required this.onLongPress,
  }) : super(key: key);

  @override
  _PackageTileState createState() => _PackageTileState();
}

class _PackageTileState extends State<PackageTile>
    with ContextualMenuStoreConsumer, DeviceAppsStoreConsumer {
  static const _kLeadingSize = Size.square(50);

  bool get _hasIcon => widget.package is ApplicationWithIcon;

  Uint8List? get _icon =>
      _hasIcon ? (widget.package as ApplicationWithIcon).icon : null;

  bool get _isSelected => widget.isSelected;

  Widget? _buildTrailing() {
    Widget? child;

    if (widget.showCheckbox) {
      child = AppIconButton(
        onTap: () => store.toggleSelect(widget.package),
        tooltip: 'Toggle Select',
        icon: Icon(
          _isSelected ? Pixel.checkbox : Pixel.checkboxon,
        ),
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
      widget.package.appName,
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
      style: TextStyle(
        color: context.theme.disabledColor.withOpacity(0.6),
      ),
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
          bottom: BorderSide(color: context.theme.backgroundColor),
        ),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(0),
        elevation: 0,
        color: Colors.transparent,
        child: _buildInkEffectWrapper(),
      ),
    );
  }
}
