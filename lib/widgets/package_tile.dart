import 'dart:typed_data';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/constants/app_spacing.dart';
import 'package:kanade/icons/pixel_art_icons.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/widgets/dotted_background.dart';
import 'package:kanade/widgets/multi_animated_builder.dart';
import 'package:kanade/widgets/toast.dart';

import 'app_icon_button.dart';

class PackageTile extends StatefulWidget {
  final Application package;

  const PackageTile(
    this.package, {
    Key? key,
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

  bool get _isSelected =>
      menuStore.context.isSelection && store.isSelected(widget.package);

  void _onLongPress() {
    menuStore.showSelectionMenu();
    store.toggleSelect(widget.package);
  }

  void _onPressed() async {
    if (menuStore.context.isSelection) {
      store.toggleSelect(widget.package);
    } else {
      final extractedApk = await store.extractApk(widget.package);

      showToast(context, 'Extracted to ${extractedApk.path}');
    }
  }

  Widget? _buildTrailing() {
    return MultiAnimatedBuilder(
      animations: [store, menuStore],
      builder: (context, child) {
        Widget? child;

        if (menuStore.context.isSelection) {
          child = AppIconButton(
            onTap: () => store.toggleSelect(widget.package),
            tooltip: 'Toggle Select',
            icon: Icon(
              _isSelected ? PixelArt.checkbox : PixelArt.checkbox_on,
            ),
          );
        }

        return SizedBox(
          width: _kLeadingSize.width,
          height: _kLeadingSize.height,
          child: child,
        );
      },
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
      child: RepaintBoundary(
        child: Center(
          child: _hasIcon
              ? Image.memory(_icon!, gaplessPlayback: true)
              : const Icon(PixelArt.android),
        ),
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
    return AnimatedBuilder(
      animation: store,
      builder: (context, child) => InkWell(
        splashFactory: InkSplash.splashFactory,
        onTap: _onPressed,
        onLongPress: _onLongPress,
        splashColor: kWhite03,
        highlightColor: kWhite03,
        child: DecoratedBox(
          decoration: _createBoxDecoration(),
          child: _buildListTile(),
        ),
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
        child: DottedBackground(
          color: kWhite10,
          size: k3dp,
          child: _buildInkEffectWrapper(),
        ),
      ),
    );
  }
}
