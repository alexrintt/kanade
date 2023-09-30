import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_storage/shared_storage.dart';

import '../stores/localization_store.dart';
import '../utils/app_localization_strings.dart';
import '../utils/package_bytes.dart';
import 'app_list_tile.dart';
import 'image_uri.dart';
import 'toast.dart';

class ApkFileTile extends StatefulWidget {
  const ApkFileTile(this.file, {super.key, this.icon});

  final DocumentFile file;
  final DocumentFile? icon;

  @override
  State<ApkFileTile> createState() => _ApkFileTileState();
}

class _ApkFileTileState extends State<ApkFileTile> with LocalizationStoreMixin {
  String get formattedBytes => (widget.file.size ?? 0).formatBytes();

  DateTime? get _lastModified => widget.file.lastModified;

  DateFormat get dateFormatter => DateFormat.yMMMd(
        localizationStore.locale.toLanguageTag(),
      );

  String get formattedDate =>
      _lastModified != null ? dateFormatter.format(_lastModified!) : '';

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: PackageImageUri(uri: widget.icon?.uri),
      title: Text('${widget.file.name}'),
      subtitle: Text('$formattedBytes, $formattedDate'),
      onTap: () async {
        try {
          await DevicePackages.installPackage(installerUri: widget.file.uri);
        } on InvalidInstallerException {
          if (mounted) {
            showToast(context, context.strings.invalidApkItWasProbablyDeleted);
          }
        }
      },
    );
  }
}
