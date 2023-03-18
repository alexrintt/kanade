import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../utils/app_icons.dart';
import 'app_list_tile.dart';

enum ApkFileTileAction {
  /// Launch the default explorer with the current file folder as initial folder.
  open,

  /// Start share intent.
  share,

  /// Request install the apk.
  install,

  /// Delete the apk file.
  delete,

  /// There is no way to uninstall since it is a file, not an installed application.
}

class ApkFilePopupMenu extends StatefulWidget {
  const ApkFilePopupMenu({super.key});

  @override
  State<ApkFilePopupMenu> createState() => _ApkFilePopupMenuState();
}

class _ApkFilePopupMenuState extends State<ApkFilePopupMenu> {
  @override
  Widget build(BuildContext context) {
    return _buildPopupMenu();
  }

  Widget _buildPopupMenu() {
    return SimpleDialog(
      children: <Widget>[
        AppListTile(
          title: const Text('Open file location'),
          leading: const Icon(AppIcons.folder, size: kDefaultIconSize),
          onTap: () {
            context.pop<ApkFileTileAction>(ApkFileTileAction.open);
          },
        ),
        AppListTile(
          title: const Text('Share apk'),
          leading: const Icon(AppIcons.share, size: kDefaultIconSize),
          onTap: () {
            context.pop<ApkFileTileAction>(ApkFileTileAction.share);
          },
        ),
        AppListTile(
          title: const Text('Install apk'),
          leading: const Icon(AppIcons.arrowDown, size: kDefaultIconSize),
          onTap: () {
            context.pop<ApkFileTileAction>(ApkFileTileAction.install);
          },
        ),
        AppListTile(
          title: const Text('Delete file'),
          leading: const Icon(
            AppIcons.delete,
            size: kDefaultIconSize,
            color: Colors.red,
          ),
          onTap: () {
            context.pop<ApkFileTileAction>(ApkFileTileAction.delete);
          },
        ),
      ],
    );
  }
}
