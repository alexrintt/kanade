import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';
import 'package:shared_storage/saf.dart' as saf;

import '../setup.dart';
import '../utils/debounce.dart';
import '../utils/mime_types.dart';
import 'bottom_navigation_store.dart';
import 'global_file_change_store.dart';
import 'indexed_collection_store.dart';

part 'background_task_store.g.dart';

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
        '${createdAt.microsecondsSinceEpoch}'
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
      if (await saf.exists(apkIconUri!) ?? false) {
        await saf.delete(apkIconUri!);
      }
    }
    if (apkDestinationUri != null) {
      if (await saf.exists(apkDestinationUri!) ?? false) {
        await saf.delete(apkDestinationUri!);
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

  // Run light computations, basically fetch the icon and the basic metadata.
  Stream<TaskProgress> prepare() async* {
    yield progress = const TaskProgress(
      // TODO: Add stream based API on shared_storage.
      // So we can use the percent correctly instead of hardcoded values.
      percent: 0,
      status: TaskStatus.running,
    );

    late final PackageInfo packageInfo;

    if (!(await saf.exists(parentUri) ?? false) ||
        !(await saf.canWrite(parentUri) ?? false)) {
      yield progress = const TaskProgress(
        // TODO: Add stream based API on shared_storage.
        // So we can use the percent correctly instead of hardcoded values.
        percent: 0,
        status: TaskStatus.failed,
        exception: TaskException.permission,
      );
    } else {
      try {
        packageInfo =
            await DevicePackages.getPackage(packageId, includeIcon: true);

        size = packageInfo.length;
        packageName = packageInfo.name;

        if (packageInfo.installerPath == null) {
          yield progress = const TaskProgress.notFound();
        } else {
          final File apkSourceFile = File(packageInfo.installerPath!).absolute;

          apkSourceFilePath = apkSourceFile.path;

          if (!apkSourceFile.existsSync()) {
            yield progress = const TaskProgress.notFound();
          } else {
            final String apkFilename =
                packageInfo.name ?? basename(apkSourceFile.path);

            // Touch the container file we will use to copy the apk.
            final saf.DocumentFile? createdFile = await saf.createFile(
              parentUri,
              mimeType: kApkMimeType,
              displayName: apkFilename,
              // Do not copy the apk source content yet!
              // Just create an empty container.
              // The heavy task of copying the apk source content to this container
              // is done by [run]. Remember that an apk can have up to gigabytes of bytes...
              bytes: Uint8List.fromList(<int>[]),
            );

            apkDestinationUri = createdFile?.uri;
            apkDestinationFileName = createdFile?.name;

            if (createdFile?.name == null) {
              yield progress = const TaskProgress(
                percent: 0.9,
                status: TaskStatus.failed,
                exception: TaskException.unknown,
              );
            } else {
              // It is better to save a local copy of the apk file icon.
              // Because Android does not have an way to load arbitrary apk file icon from URI, only Files.
              // https://stackoverflow.com/questions/58026104/get-the-real-path-of-apk-file-from-uri-shared-from-other-application#comment133215619_58026104.
              // So we would be required to copy the apk uri to a local file, which translates to very poor performance if the apk is too big.
              // it is far more performant to just load a simple icon from a file.
              // Note that this effort is to keep the app far away from MANAGE_EXTERNAL_STORAGE permission
              // and keep it valid for PlayStore.
              final saf.DocumentFile? apkIconDocumentFile =
                  await saf.createFile(
                parentUri,
                mimeType: 'application/octet-stream',
                displayName: '${createdFile!.name!}_icon',
                bytes: packageInfo.icon,
              );

              apkIconUri = apkIconDocumentFile?.uri;

              yield progress = const TaskProgress(
                percent: 0.0,
                status: TaskStatus.queued,
              );
            }
          }
        }
      } on PackageNotFoundException {
        yield progress = const TaskProgress.notFound();
      }
    }
  }

  Stream<TaskProgress> run() async* {
    yield progress = const TaskProgress(
      percent: 0.2,
      status: TaskStatus.running,
    );

    await saf.copy(Uri.file(apkSourceFile!.path), apkDestinationUri!);

    yield progress = const TaskProgress(
      percent: 0.9,
      status: TaskStatus.running,
    );

    if (apkIconUri != null) {
      yield progress = const TaskProgress(
        percent: 1,
        status: TaskStatus.finished,
      );
    } else {
      yield progress = const TaskProgress(
        percent: 1,
        exception: TaskException.unknown,
        status: TaskStatus.partial,
      );
    }
  }
}

mixin BackgroundTaskStoreMixin {
  BackgroundTaskStore? _backgroundTaskStore;
  BackgroundTaskStore get backgroundTaskStore =>
      _backgroundTaskStore ??= getIt<BackgroundTaskStore>();
}

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
      task.requestDelete();
    }

    unawaited(_runExecutorLooper());
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

        break;
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
              tasks.map((ExtractApkBackgroundTask e) => e.toJson()).toList()
        },
      ),
    );
  }

  Future<void> _saveTasks(List<ExtractApkBackgroundTask> tasks) async {
    debounce(() => __saveTasks(tasks));
  }

  Future<void> queueMany(List<ExtractApkBackgroundTask> tasks) async {
    for (final ExtractApkBackgroundTask task in tasks) {
      _tasks[task.id] = task;
    }

    unawaited(_runExecutorLooper());
    notifyListeners();
  }

  bool get _hasPendingTasks => tasks
      .any((ExtractApkBackgroundTask task) => task.progress.status.isPending);

  bool get _hasNoPendingTasks => !_hasPendingTasks;

  bool get idle => _hasNoPendingTasks;

  StreamSubscription<TaskProgress>? _currentRunningTaskListener;

  Future<void> _runExecutorLooper() async {
    if (_currentRunningTaskListener != null) return;

    if (_hasNoPendingTasks) return;

    Future<void> cancel() async {
      await _currentRunningTaskListener!.cancel();
      _currentRunningTaskListener = null;
      await _saveTasks(tasks);
      await _runExecutorLooper();
    }

    final List<ExtractApkBackgroundTask> pendingTasks = tasks.reversed
        .where(
          (ExtractApkBackgroundTask task) => task.progress.status.isPending,
        )
        .toList();

    ExtractApkBackgroundTask? firstTaskWith(TaskStatus status) {
      return pendingTasks.cast<ExtractApkBackgroundTask?>().firstWhere(
            (ExtractApkBackgroundTask? task) => task?.progress.status == status,
            orElse: () => null,
          );
    }

    bool hasTaskWith(TaskStatus status) {
      return firstTaskWith(status) != null;
    }

    final bool hasTasksAlreadyRunning = hasTaskWith(TaskStatus.running);

    if (hasTasksAlreadyRunning) return;

    final ExtractApkBackgroundTask? taskWithInitialStatus =
        firstTaskWith(TaskStatus.initial);

    if (taskWithInitialStatus != null) {
      final ExtractApkBackgroundTask task = taskWithInitialStatus;

      final Stream<TaskProgress> onTaskEnd = taskWithInitialStatus.prepare();

      _currentRunningTaskListener = onTaskEnd.listen(
        (TaskProgress _) {
          if (task.apkDestinationUri != null && task.apkIconUri != null) {
            getIt<GlobalFileChangeStore>()
              ..commit(
                action: FileAction.create,
                uri: task.apkDestinationUri!,
              )
              ..commit(action: FileAction.create, uri: task.apkIconUri!);
          }
          notifyListeners();
        },
        cancelOnError: true,
        onDone: cancel,
        onError: (_) => cancel(),
      );

      return;
    }

    final ExtractApkBackgroundTask? queuedTask =
        firstTaskWith(TaskStatus.queued);

    if (queuedTask != null) {
      final ExtractApkBackgroundTask task = queuedTask;

      final Stream<TaskProgress> taskStream = task.run();

      _currentRunningTaskListener = taskStream.listen(
        (TaskProgress progress) {
          if (!progress.status.isPending) {
            if (task.apkDestinationUri != null && task.apkIconUri != null) {
              getIt<GlobalFileChangeStore>()
                ..commit(
                  action: FileAction.update,
                  uri: task.apkDestinationUri!,
                )
                ..commit(action: FileAction.update, uri: task.apkIconUri!);
            }
            notifyListeners();
          }
        },
        cancelOnError: true,
        onDone: cancel,
        onError: (_) => cancel(),
      );

      return;
    }

    final ExtractApkBackgroundTask? taskAlreadyDeleted =
        firstTaskWith(TaskStatus.deleted);

    if (taskAlreadyDeleted != null) {
      _tasks.remove(taskAlreadyDeleted.id);
      notifyListeners();
      unawaited(_runExecutorLooper());
      return;
    }

    final ExtractApkBackgroundTask? taskWaitingForDeletion =
        firstTaskWith(TaskStatus.deleteRequested);

    if (taskWaitingForDeletion != null) {
      final ExtractApkBackgroundTask task = taskWaitingForDeletion;

      final Stream<TaskProgress> onTaskEnd = taskWaitingForDeletion.delete();

      _currentRunningTaskListener = onTaskEnd.listen(
        (TaskProgress _) {
          if (task.progress.status == TaskStatus.deleted) {
            if (task.apkDestinationUri != null && task.apkIconUri != null) {
              getIt<GlobalFileChangeStore>()
                ..commit(
                  action: FileAction.delete,
                  uri: task.apkDestinationUri!,
                )
                ..commit(action: FileAction.delete, uri: task.apkIconUri!);
            }
            _tasks.remove(task.id);

            notifyListeners();
          }
        },
        cancelOnError: true,
        onDone: cancel,
        onError: (_) => cancel(),
      );

      return;
    }
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
      item.apkSourceFile?.path ?? '',
      item.size?.toString() ?? '',
      item.apkDestinationUri?.toString() ?? '',
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
