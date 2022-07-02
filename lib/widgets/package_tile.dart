import 'dart:typed_data';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/constants/app_spacing.dart';
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
      selectedTileColor: kWhite03,
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
      border: Border(
        left: BorderSide(
          color: _isSelected ? kAccent100 : Colors.transparent,
          width: k2dp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: k2dp,
        horizontal: k5dp,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(k2dp),
        clipBehavior: Clip.hardEdge,
        color: kCardColor,
        elevation: k1dp,
        shadowColor: Theme.of(context).scaffoldBackgroundColor,
        child: _buildInkEffectWrapper(),
      ),
    );
  }
}
