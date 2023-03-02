// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_task_store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskProgress _$TaskProgressFromJson(Map<String, dynamic> json) => TaskProgress(
      percent: (json['percent'] as num).toDouble(),
      status: $enumDecode(_$TaskStatusEnumMap, json['status']),
      exception: $enumDecodeNullable(_$TaskExceptionEnumMap, json['exception']),
    );

Map<String, dynamic> _$TaskProgressToJson(TaskProgress instance) =>
    <String, dynamic>{
      'percent': instance.percent,
      'status': _$TaskStatusEnumMap[instance.status]!,
      'exception': _$TaskExceptionEnumMap[instance.exception],
    };

const _$TaskStatusEnumMap = {
  TaskStatus.queued: 'queued',
  TaskStatus.running: 'running',
  TaskStatus.finished: 'finished',
  TaskStatus.partial: 'partial',
  TaskStatus.failed: 'failed',
};

const _$TaskExceptionEnumMap = {
  TaskException.corrupt: 'corrupt',
  TaskException.notFound: 'notFound',
  TaskException.unknown: 'unknown',
  TaskException.permission: 'permission',
};

ExtractApkBackgroundTask _$ExtractApkBackgroundTaskFromJson(
        Map<String, dynamic> json) =>
    ExtractApkBackgroundTask(
      packageId: json['packageId'] as String,
      parentUri: Uri.parse(json['parentUri'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      progress: TaskProgress.fromJson(json['progress'] as Map<String, dynamic>),
      apkIconUri: json['apkIconUri'] == null
          ? null
          : Uri.parse(json['apkIconUri'] as String),
      packageName: json['packageName'] as String?,
      size: json['size'] as int?,
    )
      ..apkSourceFilePath = json['apkSourceFilePath'] as String?
      ..apkDestinationUri = json['apkDestinationUri'] == null
          ? null
          : Uri.parse(json['apkDestinationUri'] as String)
      ..apkDestinationFileName = json['apkDestinationFileName'] as String?;

Map<String, dynamic> _$ExtractApkBackgroundTaskToJson(
        ExtractApkBackgroundTask instance) =>
    <String, dynamic>{
      'parentUri': instance.parentUri.toString(),
      'packageId': instance.packageId,
      'createdAt': instance.createdAt.toIso8601String(),
      'apkIconUri': instance.apkIconUri?.toString(),
      'packageName': instance.packageName,
      'size': instance.size,
      'apkSourceFilePath': instance.apkSourceFilePath,
      'apkDestinationUri': instance.apkDestinationUri?.toString(),
      'apkDestinationFileName': instance.apkDestinationFileName,
      'progress': instance.progress,
    };
