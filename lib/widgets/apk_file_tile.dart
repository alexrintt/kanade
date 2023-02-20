import 'dart:io';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:shared_storage/shared_storage.dart';

import '../stores/localization_store.dart';
import '../utils/package_bytes.dart';
import 'loading_dots.dart';

class ApkFileTile extends StatefulWidget {
  const ApkFileTile(this.file, {super.key});

  final DocumentFile file;

  @override
  State<ApkFileTile> createState() => _ApkFileTileState();
}

class _ApkFileTileState extends State<ApkFileTile> with LocalizationStoreMixin {
  late Future<DocumentBitmap?> _bitmap;

  @override
  void initState() {
    super.initState();

    _bitmap = getDocumentThumbnail(
      uri: widget.file.uri,
      width: 50,
      height: 50,
    );
  }

  @override
  void didUpdateWidget(covariant ApkFileTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    _bitmap = getDocumentThumbnail(
      uri: widget.file.uri,
      width: 50,
      height: 50,
    );
  }

  String get formattedBytes => (widget.file.size ?? 0).formatBytes();

  DateTime? get _lastModified => widget.file.lastModified;

  DateFormat get dateFormatter => DateFormat.yMMMd(
        localizationStore.locale.toLanguageTag(),
      );

  String get formattedDate =>
      _lastModified != null ? dateFormatter.format(_lastModified!) : '';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        height: 50,
        width: 50,
        child: FutureBuilder<DocumentBitmap?>(
          future: _bitmap,
          builder:
              (BuildContext context, AsyncSnapshot<DocumentBitmap?> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
              case ConnectionState.active:
                return const DotLoadingIndicator();
              case ConnectionState.done:
                if (snapshot.hasData) {
                  return Image.memory(snapshot.data!.bytes!);
                } else {
                  return const Icon(Pixel.android);
                }
            }
          },
        ),
      ),
      title: Text('${widget.file.name}'),
      subtitle: Text('$formattedBytes, $formattedDate'),
      onTap: () async {
        await DevicePackages.installPackage(installerUri: widget.file.uri);
      },
    );
  }
}

class ApkAnalysis {
  ApkAnalysis({this.uri, String? path, File? file})
      : assert(uri != null || path != null || file != null),
        file = file ?? (path != null ? File(path) : null);

  final Uri? uri;
  final File? file;
}
