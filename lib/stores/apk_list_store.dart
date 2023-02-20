import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_storage/shared_storage.dart';

import '../setup.dart';
import '../utils/is_disposed_mixin.dart';
import '../utils/throttle.dart';
import 'device_apps.dart';
import 'settings.dart';

class ApkListStoreMixin {
  ApkListStore? _apkListStore;
  ApkListStore get apkListStore => _apkListStore ??= getIt<ApkListStore>();
}

class ApkListStore extends ChangeNotifier with IsDisposedMixin {
  final void Function(void Function()) throttle =
      throttleIt(const Duration(milliseconds: 250));

  SettingsStore get _settingsStore => getIt<SettingsStore>();

  Stream<DocumentFile>? _filesStream;
  StreamSubscription<DocumentFile>? _filesStreamSubscription;
  bool loading = true;

  final List<DocumentFile> _files = <DocumentFile>[];

  List<DocumentFile> get files => List<DocumentFile>.unmodifiable(
        _files
            .where(
              (DocumentFile element) =>
                  element.type == DeviceAppsStore.kApkMimeType,
            )
            .toList()
          ..sort(
            (DocumentFile a, DocumentFile z) =>
                (z.lastModified?.millisecondsSinceEpoch ?? 0) -
                (a.lastModified?.millisecondsSinceEpoch ?? 0),
          ),
      );

  Uri? currentUri;

  Future<void> start() async {
    _settingsStore.addListener(reload);
    await reload();
  }

  @override
  void dispose() {
    _settingsStore.removeListener(reload);

    super.dispose();
  }

  Future<void> reload() async {
    currentUri = _settingsStore.exportLocation;

    await _filesStreamSubscription?.cancel();
    _filesStream = null;
    _files.clear();
    loading = false;

    if (currentUri == null) {
      return notifyListeners();
    }

    loading = true;

    _filesStream = listFiles(
      currentUri!,
      columns: <DocumentFileColumn>[
        DocumentFileColumn.id,
        DocumentFileColumn.displayName,
        DocumentFileColumn.mimeType,
        DocumentFileColumn.size,
        DocumentFileColumn.summary,
        DocumentFileColumn.lastModified,
      ],
    );

    _filesStream!.listen(
      (DocumentFile file) {
        _files.add(file);
        throttle(() {
          notifyListeners();
        });
      },
      onDone: () {
        loading = false;
        notifyListeners();
      },
      cancelOnError: true,
      onError: (_) {
        loading = false;
        notifyListeners();
      },
    );
  }
}
