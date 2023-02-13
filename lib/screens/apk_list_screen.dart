import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:intl/intl.dart';
import 'package:shared_storage/saf.dart';

import '../setup.dart';
import '../stores/localization_store.dart';
import '../stores/settings.dart';
import '../utils/is_disposed_mixin.dart';
import '../utils/package_bytes.dart';
import '../utils/throttle.dart';
import '../widgets/contextual_menu.dart';
import '../widgets/multi_animated_builder.dart';

class ApkListStore extends ChangeNotifier with IsDisposedMixin {
  final void Function(void Function()) throttle =
      throttleIt(const Duration(milliseconds: 250));

  SettingsStore get _settingsStore => getIt<SettingsStore>();

  Stream<DocumentFile>? _filesStream;
  StreamSubscription<DocumentFile>? _filesStreamSubscription;
  bool loading = true;

  List<DocumentFile> files = <DocumentFile>[];

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
    files.clear();
    loading = false;

    if (currentUri == null) {
      return;
    }

    loading = true;

    // Cancel previous subscription before starting a new one.
    if (_filesStreamSubscription != null) {
      await _filesStreamSubscription!.cancel();
    }

    _filesStream = listFiles(
      _settingsStore.exportLocation!,
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
        files.add(file);
        throttle(() {
          if (!isDisposed) {
            notifyListeners();
          }
        });
      },
      onDone: () {
        loading = false;
        if (!isDisposed) {
          notifyListeners();
        }
      },
      cancelOnError: true,
      onError: (_) {
        loading = false;
        if (!isDisposed) {
          notifyListeners();
        }
      },
    );
  }
}

class ApkListScreen extends StatefulWidget {
  const ApkListScreen({super.key});

  @override
  State<ApkListScreen> createState() => _ApkListScreenState();
}

class _ApkListScreenState extends State<ApkListScreen>
    with LocalizationStoreMixin<ApkListScreen> {
  late ApkListStore _apkListStore;

  @override
  void initState() {
    super.initState();

    _apkListStore = ApkListStore()..start();
  }

  @override
  void dispose() {
    _apkListStore.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _apkListStore.reload,
      child: CustomScrollView(
        slivers: <Widget>[
          ContextualMenu(onSearch: () {}),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: k3dp),
            sliver: MultiAnimatedBuilder(
              animations: <Listenable>[_apkListStore, localizationStore],
              builder: (BuildContext context, Widget? child) {
                if (_apkListStore.currentUri == null) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('There is no export location configured'),
                    ),
                  );
                }

                final List<DocumentFile> files = _apkListStore.files;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final String formattedBytes =
                          (files[index].size ?? 0).formatBytes();

                      final DateTime? lastModified = files[index].lastModified;

                      final DateFormat dateFormatter = DateFormat.yMMMd(
                        localizationStore.locale.toLanguageTag(),
                      );

                      final String formattedDate = lastModified != null
                          ? dateFormatter.format(lastModified)
                          : '';

                      return ListTile(
                        title: Text('${files[index].name}'),
                        subtitle: Text('$formattedBytes, $formattedDate'),
                        onTap: () async {
                          // final Uint8List? content = await  files[index].getContent();

                          // if(content!= null) {

                          // }

                          await files[index].open();
                        },
                      );
                    },
                    childCount: files.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
