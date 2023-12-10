import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:talker_logger/talker_logger.dart';

final parser = ArgParser()
  ..addOption('watch', mandatory: true)
  ..addFlag('recursive', defaultsTo: false)
  ..addOption('ext')
  ..addOption('exec', mandatory: true);

final logger = TalkerLogger();

void main(List<String> args) {
  final results = parser.parse(args);

  logger.warning('Press Q or C to exit');

  final watch = results['watch'] as String;
  final exec = results['exec'] as String;
  final recursive = results['recursive'] as bool;

  final targetWatchDir = normalize(join(_workDir, watch));

  final targetDirs = [Directory(targetWatchDir)];

  for (final dir in targetDirs) {
    _watchAndTriggerExecWhenChanged(dir, exec, recursive: recursive);
  }

  // Listen for SIGINT and exit the program when received
  ProcessSignal.sigint.watch().listen((_) {
    print('Its falling here!');
    exit(0);
  });

  stdin
    ..echoMode = false
    ..lineMode = false;

  stdin.map(utf8.decode).listen((event) {
    if (event.toLowerCase() == 'q' || event.toLowerCase() == 'c') {
      logger.verbose('Exiting...');
      exit(0);
    }
  });
}

void _watchAndTriggerExecWhenChanged(
  Directory dir,
  String exec, {
  bool recursive = false,
}) {
  logger.info('Watching ${dir.path}');

  final watcher = dir.watch(recursive: recursive);

  watcher.listen((event) async {
    final modified = event.type & FileSystemEvent.modify != 0;
    final created = event.type & FileSystemEvent.create != 0;
    final deleted = event.type & FileSystemEvent.delete != 0;

    final eventTypeDetailsMsg = [
      if (modified) 'Modified',
      if (created) 'Created',
      if (deleted) 'Deleted',
    ].join(' | ');

    if (modified || created || deleted) {
      logger.warning(
        'File changed: ${event.path} -> $exec\n'
        '$eventTypeDetailsMsg',
      );
      _execute(exec);
    }
  });
}

Future<void> _execute(String exec) async {
  try {
    final process = await Process.start(
      exec,
      [],
      workingDirectory: _workDir,
      runInShell: true,
    );

    process.stdout.listen((e) => stdout.add(e));
    process.stderr.listen((e) => stderr.add(e));
  } catch (e) {
    logger.error(_describeError(e));
  }
}

String _describeError(dynamic e) {
  if (e is ProcessException) {
    return 'ProcessException: ${e.message}';
  } else if (e is IOException) {
    return 'IOException: $e';
  } else if (e is ArgumentError) {
    return 'ArgumentError: ${e.message}';
  } else {
    return 'Unknown error: $e';
  }
}

String get _workDir {
  return Directory.current.path;
}
