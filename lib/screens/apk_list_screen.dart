
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:shared_storage/saf.dart';

import '../stores/apk_list_store.dart';
import '../stores/localization_store.dart';
import '../widgets/apk_file_tile.dart';
import '../widgets/apk_list_progress_stepper.dart';
import '../widgets/contextual_menu.dart';
import '../widgets/multi_animated_builder.dart';

class ApkListScreen extends StatefulWidget {
  const ApkListScreen({super.key});

  @override
  State<ApkListScreen> createState() => _ApkListScreenState();
}

class _ApkListScreenState extends State<ApkListScreen>
    with LocalizationStoreMixin, ApkListStoreMixin {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: apkListStore.reload,
      child: CustomScrollView(
        slivers: <Widget>[
          ContextualMenu(onSearch: () {}),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: k3dp),
            sliver: MultiAnimatedBuilder(
              animations: <Listenable>[apkListStore, localizationStore],
              builder: (BuildContext context, Widget? child) {
                final List<DocumentFile> files = apkListStore.files;

                if (apkListStore.currentUri == null || files.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: ApkListProgressStepper()),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return ApkFileTile(files[index]);
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
