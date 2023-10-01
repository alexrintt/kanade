import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_storage/shared_storage.dart';

import '../stores/device_apps_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/copy_to_clipboard.dart';
import '../utils/generate_play_store_uri.dart';
import '../utils/install_package.dart';
import '../utils/open_url.dart';
import '../utils/share_file.dart';
import 'image_uri.dart';
import 'main_action_popup_menu.dart';
import 'toast.dart';

enum ApkFileTileAction {
  delete,
  share,
  install,
  openFileLocation,
  // Soon...
  analyze;
}

class ApkFileMenuOptions extends StatefulWidget {
  const ApkFileMenuOptions({
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
    required this.onDelete,
  });

  final Uri? iconUri;
  final Uint8List? iconBytes;
  final VoidCallback onDelete;

  final String? packageId;
  final String? packageName;
  final String subtitle;
  final String title;

  final Uri? packageInstallerUri;
  final File? packageInstallerFile;

  final bool fetchIconUriAsThumbnail;

  @override
  State<ApkFileMenuOptions> createState() => _ApkFileMenuOptionsState();
}

class _ApkFileMenuOptionsState extends State<ApkFileMenuOptions>
    with DeviceAppsStoreMixin {
  Future<void> perform(ApkFileTileAction action) async {
    switch (action) {
      case ApkFileTileAction.delete:
        // Unfortunalelly I cannot listen for file deletions using SAF,
        // so the solution is let the parent handle the deletion and broadcast to other storages.
        widget.onDelete();
      case ApkFileTileAction.share:
        await tryShareFile(
          uri: widget.packageInstallerUri,
          file: widget.packageInstallerFile,
        );
      case ApkFileTileAction.install:
        await installPackage(
          file: widget.packageInstallerFile,
          uri: widget.packageInstallerUri,
        );
      case ApkFileTileAction.analyze:
        if (mounted) {
          showToast(context, context.strings.soonEllipsis);
        }
      case ApkFileTileAction.openFileLocation:
        if (widget.packageInstallerUri == null) {
          if (mounted) {
            showToast(context, context.strings.couldNotFindTargetFile);
          }
          return;
        }

        final bool success = await openDocumentFile(
          // This removes the "document" part
          // which is used to identify the apk. And takes only the [tree]
          // part which is used to (generally) identify the directory.
          // This may not work on all devices.
          widget.packageInstallerUri!.replace(
            pathSegments: widget.packageInstallerUri!.pathSegments
                .takeWhile((String value) => value != 'document')
                .toList(),
          ),
        );

        if (!success) {
          if (mounted) {
            showToast(
              context,
              context.strings.couldNotFindFileLocationWithExplanation,
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
          icon: Icon(AppIcons.playStore.data, size: AppIcons.playStore.size),
          tooltip: context.strings.openOnPlayStore,
          text: context.strings.openOnPlayStore,
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
          icon: Icon(AppIcons.name.data, size: AppIcons.name.size),
          tooltip: context.strings.copyPackageName,
          onTap: () {
            if (widget.packageName != null) {
              context.copyTextToClipboardAndShowToast(widget.packageName!);
            } else {
              showToast(context, context.strings.packageNameIsNotAvailable);
            }
          },
        ),
        ActionButton(
          text: context.strings.delete,
          icon: Icon(
            AppIcons.delete.data,
            size: kDefaultIconSize,
            color: Colors.red,
          ),
          tooltip: context.strings.delete,
          onTap: () {
            perform(ApkFileTileAction.delete);
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
            perform(ApkFileTileAction.install);
          },
          text: context.strings.install,
          tooltip: context.strings.installApk,
        ),
        ActionButton(
          icon: Icon(
            AppIcons.share.data,
            size: AppIcons.share.size,
          ),
          onTap: () {
            perform(ApkFileTileAction.share);
          },
          text: context.strings.share,
          tooltip: context.strings.shareApk,
        ),
        ActionButton(
          icon: Icon(
            AppIcons.folder.data,
            size: AppIcons.folder.size,
          ),
          onTap: () {
            perform(ApkFileTileAction.openFileLocation);
          },
          text: context.strings.openFileLocation,
          tooltip: context.strings.openFileLocation,
        ),
      ],
    );
  }
}
