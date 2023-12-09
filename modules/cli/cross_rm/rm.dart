import 'dart:io';

Future<void> main(List<String> args) async {
  final List<FileSystemEntity> entriesToRemove = args
      .map((String path) => path.resolveAsFileSystemEntityOrNullSync())
      .whereType<FileSystemEntity>()
      .toList();

  for (final FileSystemEntity entry in entriesToRemove) {
    await entry.rm();
  }
}

extension RemoveEntity on FileSystemEntity {
  Future<void> rm() async {
    if (this is File) {
      await (this as File).delete();
    } else if (this is Directory) {
      await (this as Directory).delete(recursive: true);
    }
  }
}

extension ParseFilePath on String {
  bool get isFileSystemEntity {
    final FileStat stat = File(this).statSync();

    return stat.type != FileSystemEntityType.notFound;
  }

  FileSystemEntity? resolveAsFileSystemEntityOrNullSync({
    bool resolveLinks = false,
  }) {
    if (isFileSystemEntity) {
      return resolveAsFileSystemEntitySync(resolveLinks: resolveLinks);
    } else {
      return null;
    }
  }

  FileSystemEntity resolveAsFileSystemEntitySync({bool resolveLinks = false}) {
    final File file = File(this);

    final FileStat stat = file.statSync();

    return switch (stat.type) {
      FileSystemEntityType.file => file,
      FileSystemEntityType.directory => Directory(this),
      FileSystemEntityType.link => (() {
          if (resolveLinks) {
            return file
                .resolveSymbolicLinksSync()
                .resolveAsFileSystemEntitySync();
          } else {
            return File(this);
          }
        })(),
      FileSystemEntityType.notFound => throw ArgumentError.value(
          this,
          'path',
          'The path "$this" does not exist.',
        ),
      _ => throw StateError('Unknown FileSystemEntityType: ${stat.type}'),
    };
  }
}
