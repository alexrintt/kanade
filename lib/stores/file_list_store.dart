import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_storage/shared_storage.dart';

import '../setup.dart';
import '../utils/is_disposed_mixin.dart';
import '../utils/mime_types.dart';
import '../utils/throttle.dart';
import 'global_file_change_store.dart';
import 'indexed_collection_store.dart';
import 'settings_store.dart';

mixin class FileListStoreMixin {
  FileListStore? _fileListStore;
  FileListStore get fileListStore => _fileListStore ??= getIt<FileListStore>();
}

class FileListStore extends IndexedCollectionStore<DocumentFile>
    with
        IsDisposedMixin,
        SearchableStoreMixin<DocumentFile>,
        SelectableStoreMixin<DocumentFile>,
        ProgressIndicatorMixin,
        FileChangeAwareMixin {
  final void Function(void Function()) throttle =
      throttleIt(const Duration(milliseconds: 250));

  SettingsStore get _settingsStore => getIt<SettingsStore>();

  Stream<DocumentFile>? _filesStream;
  StreamSubscription<DocumentFile>? _filesStreamSubscription;
  bool loading = true;

  final Map<String, DocumentFile> _files = <String, DocumentFile>{};

  @override
  List<DocumentFile> get collection => List<DocumentFile>.unmodifiable(
        super.collection.toList()..sort(_documentByLastModifiedDesc),
      );

  int _documentByLastModifiedDesc(DocumentFile a, DocumentFile z) {
    if (z.lastModified == null || a.lastModified == null) return 0;
    return z.lastModified!.compareTo(a.lastModified!);
  }

  DocumentFile? apkIconDocFileOf(DocumentFile apkDocFile) {
    return collection.cast<DocumentFile?>().firstWhere(
          (DocumentFile? documentFile) =>
              documentFile!.name == '${apkDocFile.name}_icon',
          orElse: () => null,
        );
  }

  bool _documentIsApk(DocumentFile element) => element.type == kApkMimeType;

  int _byNameAscending(DocumentFile a, DocumentFile z) =>
      (z.lastModified?.millisecondsSinceEpoch ?? 0) -
      (a.lastModified?.millisecondsSinceEpoch ?? 0);

  List<DocumentFile> get files => List<DocumentFile>.unmodifiable(
        collection.where(_documentIsApk).toList()..sort(_byNameAscending),
      );

  Uri? currentUri;

  Future<void> load() async {
    _settingsStore.addListener(reload);
    await startListeningToFileChanges();
    await reload();
  }

  @override
  Future<void> dispose() async {
    _settingsStore.removeListener(reload);
    await stopListeningToFileChanges();
    super.dispose();
  }

  Future<void> reload() async {
    currentUri = await _settingsStore.getAndSetExportLocationIfItExists();

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
        _files[getItemId(file)] = file;

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

  Future<void> deleteSelectedFiles() async {
    for (final DocumentFile file in selected) {
      await deleteFile(item: file);
    }
  }

  Future<void> deleteFile({
    DocumentFile? item,
    String? itemId,
  }) async {
    final DocumentFile? file = item ?? collectionIndexedById[itemId];

    if (file == null) return;

    try {
      getIt<GlobalFileChangeStore>()
          .commit(action: FileAction.delete, uri: file.uri);
      _files.remove(getItemId(file));
      notifyListeners();

      await file.delete();
    } on PlatformException {
      rethrow;
    }
  }

  @override
  Map<String, DocumentFile> get collectionIndexedById => _files;

  @override
  List<String> createSearchableStringsOf(DocumentFile file) {
    return <String>[
      file.name ?? '',
      file.uri.toString(),
      file.parentUri?.toString() ?? '',
      file.type ?? '',
      file.size?.toString() ?? '',
    ];
  }

  @override
  String getItemId(DocumentFile file) {
    return file.id ?? file.uri.toString();
  }

  @override
  Future<void> onFileChange(FileCommit commit) async {
    switch (commit.action) {
      case FileAction.update:
      case FileAction.create:
        final DocumentFile? freshDocumentFile =
            await commit.uri.toDocumentFile();

        if (freshDocumentFile != null) {
          _files[getItemId(freshDocumentFile)] = freshDocumentFile;
          notifyListeners();
        }

        break;
      case FileAction.delete:
        _files.removeWhere(
          (String id, DocumentFile file) => file.uri == commit.uri,
        );
        notifyListeners();
        break;
    }
  }
}
