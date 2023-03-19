import 'dart:io';
import 'dart:typed_data';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../stores/device_apps_store.dart';
import '../utils/app_icons.dart';
import '../utils/context_show_apk_result_message.dart';
import '../utils/generate_play_store_uri.dart';
import '../utils/share_file.dart';
import 'app_icon_button.dart';
import 'app_list_tile.dart';
import 'image_uri.dart';
import 'toast.dart';

enum InstalledAppTileAction {
  uninstall,
  share,
  open,
  extract;
}

class InstalledAppMenuOptions extends StatefulWidget {
  const InstalledAppMenuOptions({
    super.key,
    this.iconUri,
    this.iconBytes,
    this.packageId,
    this.packageName,
    this.packageInstallerUri,
    this.fetchIconUriAsThumbnail = false,
    this.packageInstallerFile,
  });

  final Uri? iconUri;
  final Uint8List? iconBytes;

  final String? packageId;
  final String? packageName;

  final Uri? packageInstallerUri;
  final File? packageInstallerFile;

  final bool fetchIconUriAsThumbnail;

  @override
  State<InstalledAppMenuOptions> createState() =>
      _InstalledAppMenuOptionsState();
}

class _InstalledAppMenuOptionsState extends State<InstalledAppMenuOptions>
    with DeviceAppsStoreMixin {
  Future<void> perform(InstalledAppTileAction action) async {
    switch (action) {
      case InstalledAppTileAction.extract:
        if (widget.packageId == null) return;
        final ApkExtraction extraction =
            await store.extractApk(packageId: widget.packageId);

        if (mounted) {
          context.showApkResultMessage(extraction.result);
        }
        break;
      case InstalledAppTileAction.uninstall:
        if (widget.packageId == null) return;
        await store.uninstallApp(widget.packageId!);
        break;
      case InstalledAppTileAction.share:
        await shareFile(
          uri: widget.packageInstallerUri,
          file: widget.packageInstallerFile,
        );
        break;
      case InstalledAppTileAction.open:
        if (widget.packageId == null) {
          showToast(
            context,
            'Package ID is not defined, try reloading the list',
          );
          return;
        }
        await DevicePackages.openPackage(widget.packageId!);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppListTile(
          leading: widget.iconUri != null
              ? PackageImageUri(
                  fetchThumbnail: widget.fetchIconUriAsThumbnail,
                  uri: widget.iconUri,
                )
              : PackageImageBytes(icon: widget.iconBytes),
          title: Text(
            widget.packageName ?? widget.packageId ?? 'Unnamed package',
          ),
          subtitle: widget.packageName != null && widget.packageId != null
              ? Text(widget.packageId!)
              : null,
          trailing: AppIconButton(
            icon: Icon(AppIcons.settings.data, size: AppIcons.settings.size),
            tooltip: 'Open app settings',
            onTap: () {
              if (widget.packageId != null) {
                DevicePackages.openPackageSettings(widget.packageId!);
              } else {
                showToast(
                  context,
                  'The current tile has no ID thus invalid, try reloading the list',
                );
              }
            },
          ),
        ),
        const Divider(),
        AppListTile(
          title: const Text('Open app'),
          leading: Icon(
            AppIcons.externalLink.data,
            size: AppIcons.externalLink.size,
          ),
          onTap: () {
            perform(InstalledAppTileAction.open);
          },
        ),
        AppListTile(
          title: const Text('Share apk'),
          leading: Icon(AppIcons.share.data, size: AppIcons.share.size),
          onTap: () {
            perform(InstalledAppTileAction.share);
          },
        ),
        AppListTile(
          title: const Text('Extract apk'),
          leading: Icon(AppIcons.download.data, size: AppIcons.download.size),
          onTap: () {
            perform(InstalledAppTileAction.extract);
          },
        ),
        AppListTile(
          title: const Text('Open Play Store'),
          leading: Icon(AppIcons.playStore.data, size: AppIcons.playStore.size),
          onTap: () {
            if (widget.packageId != null) {
              launchUrl(generatePlayStoreUriFromPackageId(widget.packageId!));
            }
          },
        ),
        AppListTile(
          title: const Text('Uninstall'),
          leading: Icon(
            AppIcons.delete.data,
            size: kDefaultIconSize,
            color: Colors.red,
          ),
          onTap: () {
            perform(InstalledAppTileAction.uninstall);
          },
        ),
      ],
    );
  }
}

class BottomSheetWithAnimationController extends StatefulWidget {
  const BottomSheetWithAnimationController({
    super.key,
    this.child,
    this.builder,
  }) : assert(child != null || builder != null);

  final WidgetBuilder? builder;
  final Widget? child;

  @override
  State<BottomSheetWithAnimationController> createState() =>
      _BottomSheetWithAnimationControllerState();
}

class _BottomSheetWithAnimationControllerState
    extends State<BottomSheetWithAnimationController>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return (widget.builder ?? (_) => widget.child!)(context);
  }
}
