import 'dart:io';
import 'dart:typed_data';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:shared_storage/shared_storage.dart';

import '../stores/localization_store.dart';
import '../utils/package_bytes.dart';
import 'loading_dots.dart';

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
    return ListTile(
      leading: SizedBox(
        height: 50,
        width: 50,
        child: widget.icon != null
            ? ImageUri(
                uri: widget.icon!.uri,
                loading: const DotLoadingIndicator(),
                error: const Icon(Pixel.android),
              )
            : const Icon(Pixel.android),
      ),
      title: Text('${widget.file.name}'),
      subtitle: Text('$formattedBytes, $formattedDate'),
      onTap: () async {
        await DevicePackages.installPackage(installerUri: widget.file.uri);
      },
    );
  }
}

class ImageUri extends StatefulWidget {
  const ImageUri({
    super.key,
    required this.uri,
    required this.loading,
    required this.error,
  });

  final Uri uri;
  final Widget loading;
  final Widget error;

  @override
  State<ImageUri> createState() => _ImageUriState();
}

class _ImageUriState extends State<ImageUri> {
  late Future<Uint8List?> _bitmap;

  @override
  void initState() {
    super.initState();

    _bitmap = getDocumentContent(widget.uri);
  }

  @override
  void didUpdateWidget(covariant ImageUri oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.uri != widget.uri) {
      _bitmap = getDocumentContent(widget.uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bitmap,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return widget.loading;
          case ConnectionState.done:
            if (snapshot.hasData) {
              return Image.memory(snapshot.data!);
            } else {
              return widget.error;
            }
        }
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
