// import 'package:device_packages/device_packages.dart';
// import 'package:shared_storage/shared_storage.dart' as shared_storage;

// import '../../../stores/background_task_store.dart';

// abstract class ExtractApkUsecase {
//   const ExtractApkUsecase();

//   Stream<double> extractApk({
//     required String packageId,
//     required Uri destinationUri,
//   });
// }

// class ExtractApkUsecaseImpl implements ExtractApkUsecase {
//   @override
//   Stream<double> extractApk({
//     required String packageId,
//     required Uri destinationUri,
//   }) async* {
//     yield 0;

//     late final PackageInfo packageInfo;

//     if (!(await shared_storage.exists(destinationUri) ?? false) ||
//         !(await shared_storage.canWrite(destinationUri) ?? false)) {
//         throw Exception('Cannot write to destination URI');
//     } else {
//       try {
//         packageInfo =
//             await DevicePackages.getPackage(packageId, includeIcon: true);

//         size = packageInfo.length;
//         packageName = packageInfo.name;

//         if (packageInfo.installerPath == null) {
//           yield progress = const TaskProgress.notFound();
//         } else {
//           final File apkSourceFile = File(packageInfo.installerPath!).absolute;

//           apkSourceFilePath = apkSourceFile.path;

//           if (!apkSourceFile.existsSync()) {
//             yield progress = const TaskProgress.notFound();
//           } else {
//             final String apkFilename =
//                 packageInfo.name ?? basename(apkSourceFile.path);

//             // Touch the container file we will use to copy the apk.
//             final shared_storage.DocumentFile? createdFile =
//                 await shared_storage.createFile(
//               parentUri,
//               mimeType: kApkMimeType,
//               displayName: apkFilename,
//               // Do not copy the apk source content yet!
//               // Just create an empty container.
//               // The heavy task of copying the apk source content to this container
//               // is done by [run]. Remember that an apk can have up to gigabytes of bytes...
//               bytes: Uint8List.fromList(<int>[]),
//             );

//             apkDestinationUri = createdFile?.uri;
//             apkDestinationFileName = createdFile?.name;

//             if (createdFile?.name == null) {
//               yield progress = const TaskProgress(
//                 percent: 0.9,
//                 status: TaskStatus.failed,
//                 exception: TaskException.unknown,
//               );
//             } else {
//               // It is better to save a local copy of the apk file icon.
//               // Because Android does not have an way to load arbitrary apk file icon from URI, only Files.
//               // https://stackoverflow.com/questions/58026104/get-the-real-path-of-apk-file-from-uri-shared-from-other-application#comment133215619_58026104.
//               // So we would be required to copy the apk uri to a local file, which translates to very poor performance if the apk has large size.
//               // it is far more performant to just load a simple icon from a file.
//               // Note that this effort is to keep the app far away from MANAGE_EXTERNAL_STORAGE permission
//               // and keep it valid for PlayStore.
//               final shared_storage.DocumentFile? apkIconDocumentFile =
//                   await shared_storage.createFile(
//                 parentUri,
//                 mimeType: 'application/octet-stream',
//                 displayName: '${createdFile!.name!}_icon',
//                 bytes: packageInfo.icon,
//               );

//               apkIconUri = apkIconDocumentFile?.uri;

//               yield progress = const TaskProgress(
//                 percent: 0.0,
//                 status: TaskStatus.queued,
//               );
//             }
//           }
//         }
//       } on PackageNotFoundException {
//         yield progress = const TaskProgress.notFound();
//       }
//     }
//   }

//   Stream<TaskProgress> run() async* {
//     yield progress = const TaskProgress(
//       percent: 0.2,
//       status: TaskStatus.running,
//     );

//     await shared_storage.copy(
//       Uri.file(apkSourceFile!.path),
//       apkDestinationUri!,
//     );

//     yield progress = const TaskProgress(
//       percent: 0.9,
//       status: TaskStatus.running,
//     );

//     if (apkIconUri != null) {
//       yield progress = const TaskProgress(
//         percent: 1,
//         status: TaskStatus.finished,
//       );
//     } else {
//       yield progress = const TaskProgress(
//         percent: 1,
//         exception: TaskException.unknown,
//         status: TaskStatus.partial,
//       );
//     }
//   }
// }
