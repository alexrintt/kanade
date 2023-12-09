import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';
import 'package:shared_storage/shared_storage.dart' as shared_storage;
import 'package:workmanager/workmanager.dart';

import '../setup.dart';
import '../utils/debounce.dart';
import '../utils/mime_types.dart';
import 'bottom_navigation_store.dart';
import 'global_file_change_store.dart';
import 'indexed_collection_store.dart';

part 'background_task_store.g.dart';

const PostConstruct asyncPostConstruct = PostConstruct(preResolve: true);

enum TaskStatus {
  initial,
  queued,
  running,
  finished,
  partial,
  failed,
  deleteRequested,
  deleted;

  bool get isPending =>
      this == queued ||
      this == running ||
      this == initial ||
      this == deleteRequested ||
      this == deleted;
}

enum TaskException {
  corrupt,
  notFound,
  unknown,
  permission,
}

@JsonSerializable()
class TaskProgress {
  const TaskProgress({
    required this.percent,
    required this.status,
    this.exception,
  }) : assert(percent >= 0 && percent <= 1);

  const TaskProgress.initial()
      : percent = 0,
        status = TaskStatus.initial,
        exception = null;

  const TaskProgress.notFound()
      : percent = 0,
        status = TaskStatus.failed,
        exception = TaskException.notFound;

  final double percent;
  final TaskStatus status;
  final TaskException? exception;

  static TaskProgress fromJson(Map<String, dynamic> json) =>
      _$TaskProgressFromJson(json);

  Map<String, dynamic> toJson() => _$TaskProgressToJson(this);
}

@JsonSerializable()
class ExtractApkBackgroundTask {
  ExtractApkBackgroundTask({
    required this.packageId,
    required this.parentUri,
    required this.createdAt,
    required this.progress,
    required this.apkIconUri,
    required this.packageName,
    required this.size,
  });

  ExtractApkBackgroundTask.create({
    required this.packageId,
    required this.parentUri,
    required this.createdAt,
    this.apkIconUri,
    this.packageName,
    this.size,
  });

  final Uri parentUri;
  final String packageId;
  final DateTime createdAt;

  Uri? get targetUri => apkDestinationUri;
  String? get title => apkDestinationFileName ?? packageName;

  int get sizeOrZero => size ?? 0;

  Uri? apkIconUri;
  String? packageName;
  int? size;
  String? apkSourceFilePath;
  Uri? apkDestinationUri;
  String? apkDestinationFileName;

  String get id => <String>[
        '$parentUri',
        packageId,
        '${createdAt.microsecondsSinceEpoch}',
      ].join();

  File? get apkSourceFile =>
      apkSourceFilePath != null ? File(apkSourceFilePath!) : null;

  TaskProgress progress = const TaskProgress.initial();

  static ExtractApkBackgroundTask fromJson(Map<String, dynamic> json) =>
      _$ExtractApkBackgroundTaskFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractApkBackgroundTaskToJson(this);

  Stream<TaskProgress> delete() async* {
    if (progress.status == TaskStatus.deleted) {
      // already deleted, skip.
      yield progress;
      return;
    }

    if (progress.status != TaskStatus.deleteRequested) {
      // we will only process tasks that were requested to delete.
      yield progress;
      return;
    }

    yield progress = TaskProgress(
      percent: progress.percent,
      status: TaskStatus.running,
    );

    if (apkIconUri != null) {
      if (await shared_storage.exists(apkIconUri!) ?? false) {
        await shared_storage.delete(apkIconUri!);
      }
    }
    if (apkDestinationUri != null) {
      if (await shared_storage.exists(apkDestinationUri!) ?? false) {
        await shared_storage.delete(apkDestinationUri!);
      }
    }

    yield progress = TaskProgress(
      percent: progress.percent,
      status: TaskStatus.deleted,
    );
  }

  TaskProgress requestDelete() {
    return progress = TaskProgress(
      percent: progress.percent,
      status: TaskStatus.deleteRequested,
    );
  }
}

mixin BackgroundTaskStoreMixin {
  BackgroundTaskStore? _backgroundTaskStore;
  BackgroundTaskStore get backgroundTaskStore =>
      _backgroundTaskStore ??= getIt<BackgroundTaskStore>();
}

@Singleton()
class BackgroundTaskStore
    extends IndexedCollectionStore<ExtractApkBackgroundTask>
    with
        SelectableStoreMixin<ExtractApkBackgroundTask>,
        SearchableStoreMixin<ExtractApkBackgroundTask>,
        FileChangeAwareMixin,
        PackageInstallerMixin {
  final Map<String, ExtractApkBackgroundTask> _tasks =
      <String, ExtractApkBackgroundTask>{};

  @override
  bool canBeSelected(ExtractApkBackgroundTask task) {
    return task.progress.status == TaskStatus.finished;
  }

  late DateTime _lastView;

  void markAsViewed() {
    _lastView = DateTime.now();
    notifyListeners();
  }

  int get badgeCount => collection
      .where((ExtractApkBackgroundTask e) => e.createdAt.isAfter(_lastView))
      .length;

  int _byCreationDateDesc(
    ExtractApkBackgroundTask a,
    ExtractApkBackgroundTask z,
  ) =>
      z.createdAt.millisecondsSinceEpoch - a.createdAt.millisecondsSinceEpoch;

  int get pendingTasksCount => pendingTasks.length;

  List<ExtractApkBackgroundTask> get pendingTasks =>
      List<ExtractApkBackgroundTask>.unmodifiable(
        tasks.where(
          (ExtractApkBackgroundTask task) => task.progress.status.isPending,
        ),
      );

  List<ExtractApkBackgroundTask> get tasks => collection;

  @override
  List<ExtractApkBackgroundTask> get collection {
    return List<ExtractApkBackgroundTask>.unmodifiable(
      <ExtractApkBackgroundTask>[...super.collection]
        ..sort(_byCreationDateDesc),
    );
  }

  File get _cacheFile => File(
        '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}queuedtasks.temp',
      );

  Future<void> deleteTasks(Set<ExtractApkBackgroundTask> tasks) async {
    for (final ExtractApkBackgroundTask task in tasks) {
      await Workmanager().registerOneOffTask(
        task.id,
        task.packageName!,
        inputData: <String, dynamic>{
          'packageId': task.packageId,
          'parentUri': task.parentUri,
          'type': 'DELETE',
        },
      );
    }
  }

  /// Prefer using [deleteTasks] instead if you are planning to delete several tasks.
  Future<void> deleteTask({
    ExtractApkBackgroundTask? task,
    String? taskId,
  }) async {
    assert(task != null || taskId != null);

    final String id = taskId ?? task!.id;

    if (collectionIndexedById[id] == null) return;

    return deleteTasks(<ExtractApkBackgroundTask>{collectionIndexedById[id]!});
  }

  Future<void> deleteSelectedBackgroundTasks() async {
    await deleteTasks(selected);
  }

  Future<void> deleteAllBackgroundTasks() async {
    await deleteTasks(tasks.toSet());
  }

  Future<void> cancelAllPendingBackgroundTasks() async {
    bool isPending(ExtractApkBackgroundTask task) =>
        task.progress.status.isPending;

    await deleteTasks(tasks.where(isPending).toSet());
  }

  Future<void> cancelBackgroundTask(ExtractApkBackgroundTask task) async {
    await deleteTasks(<ExtractApkBackgroundTask>{task});
  }

  @override
  void onFileChange(FileCommit commit) {
    switch (commit.action) {
      case FileAction.create:
      case FileAction.update:
        // ignore, the background task store does not cares about apks that were
        // not created by itself.
        break;
      case FileAction.delete:
        final List<String> ids = _tasks.keys.where(
          (String id) {
            final ExtractApkBackgroundTask task = _tasks[id]!;

            if (commit.uri == task.apkIconUri) {
              // The icon was deleted, ignore for now, since
              // the UI will fall back to the default icon when the icon is no longer available.
            } else if (commit.uri == task.apkDestinationUri) {
              // the apk itself was deleted, update the UI.
              return true;
            }

            return false;
          },
        ).toList();

        deleteTasks(ids.map((String id) => _tasks[id]!).toSet());
    }
  }

  @override
  Future<void> dispose() async {
    _stopNavigationTabListener();
    await stopListeningToFileChanges();
    super.dispose();
  }

  void _bottomNavigationListener() {
    if (_bottomNavigationStore.currentIndex == 1) {
      markAsViewed();
    }
  }

  BottomNavigationStore get _bottomNavigationStore =>
      getIt<BottomNavigationStore>();

  void _startNavigationTabListener() {
    _bottomNavigationStore.addListener(_bottomNavigationListener);
  }

  void _stopNavigationTabListener() {
    _bottomNavigationStore.removeListener(_bottomNavigationListener);
  }

  @asyncPostConstruct
  Future<void> load() async {
    markAsViewed();
    _startNavigationTabListener();

    await startListeningToFileChanges();

    if (!_cacheFile.existsSync()) {
      _cacheFile.createSync();
    }

    Uint8List? rawData;

    try {
      rawData = _cacheFile.readAsBytesSync();
    } on FileSystemException {
      rawData = null;
    }

    Map<String, dynamic>? json;

    try {
      if (rawData == null) {
        json = <String, String>{};
      } else {
        final String rawJson = const Utf8Decoder().convert(rawData);

        json = Map<String, dynamic>.from(
          jsonDecode(rawJson) as Map<dynamic, dynamic>,
        );
      }
    } on Exception {
      json = <String, String>{};
    }

    final List<dynamic> rawTasks = json['tasks'] is Iterable<dynamic>
        ? List<dynamic>.from(json['tasks'] as Iterable<dynamic>)
        : <dynamic>[];

    final List<ExtractApkBackgroundTask> tasks = rawTasks
        .whereType<Map<dynamic, dynamic>>()
        .where(
          (Map<dynamic, dynamic> e) =>
              e.keys.every((dynamic key) => key is String),
        )
        .cast<Map<String, dynamic>>()
        .map(ExtractApkBackgroundTask.fromJson)
        .toList();

    unawaited(_saveTasks(tasks));

    for (final ExtractApkBackgroundTask task in tasks) {
      _tasks[task.id] = task;
    }
  }

  final void Function(void Function()) debounce =
      debounceIt(const Duration(seconds: 1));

  Future<void> __saveTasks(List<ExtractApkBackgroundTask> tasks) async {
    await _cacheFile.writeAsString(
      jsonEncode(
        <String, dynamic>{
          'tasks':
              tasks.map((ExtractApkBackgroundTask e) => e.toJson()).toList(),
        },
      ),
    );
  }

  Future<void> _saveTasks(List<ExtractApkBackgroundTask> tasks) async {
    debounce(() => __saveTasks(tasks));
  }

  Future<void> queueMany(List<ExtractApkBackgroundTask> tasks) async {
    for (final ExtractApkBackgroundTask task in tasks) {
      await Workmanager().registerOneOffTask(
        task.id,
        task.packageId,
        inputData: <String, dynamic>{
          'packageId': task.packageId,
          'parentUri': task.parentUri,
          // 'type': WorkType.extract,
        },
      );
      // _tasks[task.id] = task;
    }

    notifyListeners();
  }

  @override
  Map<String, ExtractApkBackgroundTask> get collectionIndexedById => _tasks;

  @override
  String getItemId(ExtractApkBackgroundTask item) {
    return item.id;
  }

  @override
  List<String> createSearchableStringsOf(ExtractApkBackgroundTask item) {
    return <String>[
      item.packageName ?? '',
      item.packageId,
    ];
  }

  @override
  Future<void> onInstallationFailed({
    required String installationId,
    required PackageInstallationIntentResult result,
    File? file,
    Uri? uri,
    String? path,
  }) async {
    unawaited(deleteTask(taskId: installationId));
  }
}
