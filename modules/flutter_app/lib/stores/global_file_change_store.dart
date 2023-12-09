import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

enum FileAction {
  update,
  create,
  delete,
}

class FileCommit {
  const FileCommit({
    required this.uri,
    required this.action,
    required this.commitedAt,
  });

  final Uri uri;
  final FileAction action;
  final DateTime commitedAt;

  String get id => <String>[
        uri.toString(),
        action.toString(),
        commitedAt.microsecondsSinceEpoch.toString(),
      ].join();
}

/// Store that emits a new event whenever a file is deleted/updated/renamed/created etc.
/// this is intended to be a middleware between any stores that works with file
@Singleton()
class GlobalFileChangeStore extends ChangeNotifier {
  @postConstruct
  Future<void> load() {
    _controller = StreamController<FileCommit>.broadcast();

    return SynchronousFuture<void>(null);
  }

  late StreamController<FileCommit> _controller;

  void commit({required Uri uri, required FileAction action}) {
    _controller.add(
      FileCommit(
        uri: uri,
        action: action,
        commitedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Stream<FileCommit> get onFileChange => _controller.stream;

  @override
  void dispose() {
    _controller.close();

    super.dispose();
  }
}
