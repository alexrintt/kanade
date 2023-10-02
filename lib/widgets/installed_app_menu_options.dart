import 'dart:async';
import 'dart:io';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/device_apps_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_show_apk_result_message.dart';
import '../utils/copy_to_clipboard.dart';
import '../utils/generate_play_store_uri.dart';
import '../utils/open_url.dart';
import '../utils/share_file.dart';
import 'app_list_tile.dart';
import 'image_uri.dart';
import 'main_action_popup_menu.dart';
import 'toast.dart';

enum InstalledAppTileAction {
  uninstall,
  share,
  open,
  extract,
  openSettings;
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
    required this.subtitle,
    required this.title,
  });

  final Uri? iconUri;
  final Uint8List? iconBytes;

  final String? packageId;
  final String? packageName;
  final String subtitle;
  final String title;

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
        final SingleExtraction extraction =
            await store.extractApk(packageId: widget.packageId);

        if (mounted) {
          context.showApkResultMessage(extraction.result);
        }
      case InstalledAppTileAction.uninstall:
        if (widget.packageId == null) return;
        await store.uninstallApp(widget.packageId!);
      case InstalledAppTileAction.share:
        await tryShareFile(
          uri: widget.packageInstallerUri,
          file: widget.packageInstallerFile,
        );
      case InstalledAppTileAction.open:
        if (widget.packageId == null) {
          if (mounted) {
            showToast(
              context,
              'Package ID is not defined, try reloading the list',
            );
          }
          return;
        }
        try {
          await DevicePackages.openPackage(widget.packageId!);
        } on PackageIsNotOpenableException {
          if (mounted) {
            showToast(
              context,
              context.strings.couldNotStartApp,
            );
          }
        }
      case InstalledAppTileAction.openSettings:
        if (widget.packageId != null) {
          await DevicePackages.openPackageSettings(widget.packageId!);
        } else {
          if (mounted) {
            showToast(
              context,
              'The current tile has no ID thus invalid, try reloading the list',
            );
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainActionPopupMenu(
      title: widget.title,
      subtitle: widget.subtitle,
      tiles: <Widget>[
        ActionButton(
          text: context.strings.searchOnline,
          tooltip: context.strings.searchOnline,
          icon: Icon(
            AppIcons.browser.data,
            size: AppIcons.browser.size,
          ),
          onTap: () async {
            final String query = '${widget.packageName} ${widget.packageId}';

            unawaited(openUri(generateDuckDuckGoUriFromQuery(query)));
          },
        ),
        ActionButton(
          text: context.strings.openOnFDroid,
          tooltip: context.strings.openOnFDroid,
          icon: Icon(
            AppIcons.android.data,
            size: AppIcons.android.size,
          ),
          onTap: () {
            if (widget.packageId != null) {
              openUri(generateFDroidUriFromPackageId(widget.packageId!));
            }
          },
        ),
        ActionButton(
          text: context.strings.openOnPlayStore,
          tooltip: context.strings.openOnPlayStore,
          icon: Icon(AppIcons.playStore.data, size: AppIcons.playStore.size),
          onTap: () {
            if (widget.packageId != null) {
              openUri(
                generatePlayStoreUriFromPackageId(widget.packageId!),
              );
            }
          },
        ),
        ActionButton(
          text: context.strings.copyPackageId,
          tooltip: context.strings.copyPackageId,
          enabled: widget.packageId != null,
          icon: Icon(AppIcons.clipboard.data, size: AppIcons.clipboard.size),
          onTap: () {
            if (widget.packageId != null) {
              context.copyTextToClipboardAndShowToast(widget.packageId!);
            } else {
              showToast(context, context.strings.packageIdIsNotAvailable);
            }
          },
        ),
        ActionButton(
          text: context.strings.copyPackageName,
          tooltip: context.strings.copyPackageName,
          enabled: widget.packageName != null,
          icon: Icon(AppIcons.name.data, size: AppIcons.name.size),
          onTap: () {
            if (widget.packageName != null) {
              context.copyTextToClipboardAndShowToast(widget.packageName!);
            } else {
              showToast(context, context.strings.packageNameIsNotAvailable);
            }
          },
        ),
      ],
      icon: switch (null) {
        _ when widget.iconUri != null => PackageImageUri(
            fetchThumbnail: widget.fetchIconUriAsThumbnail,
            uri: widget.iconUri,
          ),
        _ => PackageImageBytes(icon: widget.iconBytes),
      },
      actionButtons: <Widget>[
        ActionButton(
          icon: Icon(
            AppIcons.download.data,
            size: AppIcons.download.size,
          ),
          onTap: () {
            perform(InstalledAppTileAction.extract);
          },
          text: context.strings.extract,
          tooltip: context.strings.extractApk,
        ),
        ActionButton(
          icon: Icon(
            AppIcons.share.data,
            size: AppIcons.share.size,
          ),
          onTap: () {
            perform(InstalledAppTileAction.share);
          },
          text: context.strings.share,
          tooltip: context.strings.shareApk,
        ),
        ActionButton(
          text: context.strings.uninstall,
          tooltip: context.strings.uninstall,
          icon: Icon(
            AppIcons.delete.data,
            size: kDefaultIconSize,
            color: context.colorScheme.error,
          ),
          onTap: () {
            context.pop();
            perform(InstalledAppTileAction.uninstall);
          },
        ),
        ActionButton(
          icon: Icon(
            AppIcons.externalLink.data,
            size: AppIcons.externalLink.size,
          ),
          onTap: () {
            perform(InstalledAppTileAction.open);
          },
          text: context.strings.launchApp,
          tooltip: context.strings.launchApp,
        ),
        ActionButton(
          icon: Icon(
            AppIcons.settings.data,
            size: AppIcons.settings.size,
          ),
          onTap: () {
            perform(InstalledAppTileAction.openSettings);
          },
          text: context.strings.settings,
          tooltip: context.strings.openSettingsPage,
        ),
      ],
    );
  }
}
