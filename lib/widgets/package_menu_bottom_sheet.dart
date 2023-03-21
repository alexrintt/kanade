import 'dart:async';
import 'dart:io';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/device_apps_store.dart';
import '../utils/app_icons.dart';
import '../utils/context_show_apk_result_message.dart';
import '../utils/copy_to_clipboard.dart';
import '../utils/generate_play_store_uri.dart';
import '../utils/open_url.dart';
import '../utils/share_file.dart';
import 'app_icon_button.dart';
import 'app_list_tile.dart';
import 'image_uri.dart';
import 'toast.dart';

enum InstalledAppTileAction {
  uninstall,
  share,
  open,
  extract,
  openSettings;
}

class InstalledAppMenuOptions extends StatefulWidget {
  const InstalledAppMenuOptions({
    super.key,
    this.iconUri,
    this.iconBytes,
    this.packageId,
    this.packageName,
    this.packageInstallerUri,
    this.fetchIconUriAsThumbnail = false,
    this.packageInstallerFile,
    required this.subtitle,
    required this.title,
  });

  final Uri? iconUri;
  final Uint8List? iconBytes;

  final String? packageId;
  final String? packageName;
  final String subtitle;
  final String title;

  final Uri? packageInstallerUri;
  final File? packageInstallerFile;

  final bool fetchIconUriAsThumbnail;

  @override
  State<InstalledAppMenuOptions> createState() =>
      _InstalledAppMenuOptionsState();
}

class _InstalledAppMenuOptionsState extends State<InstalledAppMenuOptions>
    with DeviceAppsStoreMixin {
  Future<void> perform(InstalledAppTileAction action) async {
    switch (action) {
      case InstalledAppTileAction.extract:
        if (widget.packageId == null) return;
        final SingleExtraction extraction =
            await store.extractApk(packageId: widget.packageId);

        if (mounted) {
          context.showApkResultMessage(extraction.result);
        }
        break;
      case InstalledAppTileAction.uninstall:
        if (widget.packageId == null) return;
        await store.uninstallApp(widget.packageId!);
        break;
      case InstalledAppTileAction.share:
        await shareFile(
          uri: widget.packageInstallerUri,
          file: widget.packageInstallerFile,
        );
        break;
      case InstalledAppTileAction.open:
        if (widget.packageId == null) {
          showToast(
            context,
            'Package ID is not defined, try reloading the list',
          );
          return;
        }
        try {
          await DevicePackages.openPackage(widget.packageId!);
        } on PackageIsNotOpenableException {
          showToast(
            context,
            'Could not start app, probably because it has no UI (no launch intent is declared)',
          );
        }
        break;
      case InstalledAppTileAction.openSettings:
        if (widget.packageId != null) {
          await DevicePackages.openPackageSettings(widget.packageId!);
        } else {
          showToast(
            context,
            'The current tile has no ID thus invalid, try reloading the list',
          );
        }
        break;
    }
  }

  final double _dragIndicatorWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    return _buildScaffoldWrapper(_buildScaffoldBody());
  }

  Widget _buildScaffoldBody() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Do nothing, this gesture behavior is here because we need to block
        // the modal barrier from dismissing this widget if we click in the draggable widget.
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: context.height,
        ),
        child: Column(
          children: <Widget>[
            _buildDragMeIndicator(),
            _buildPackageThumbnailHeader(),
            _buildMainActionButtons(),
            const Divider(height: 1),
            AppListTile(
              dense: true,
              title: const Text('Search online'),
              leading: Icon(
                AppIcons.browser.data,
                size: AppIcons.browser.size,
              ),
              onTap: () async {
                final String query =
                    '${widget.packageName} ${widget.packageId}';

                unawaited(openUri(generateDuckDuckGoUriFromQuery(query)));
              },
            ),
            AppListTile(
              dense: true,
              title: const Text('Open on F-Droid'),
              onLongPress: () {},
              leading: Icon(
                AppIcons.android.data,
                size: AppIcons.android.size,
              ),
              onTap: () {
                if (widget.packageId != null) {
                  openUri(generateFDroidUriFromPackageId(widget.packageId!));
                }
              },
            ),
            AppListTile(
              dense: true,
              title: const Text('Open on Play Store'),
              onLongPress: () {},
              leading:
                  Icon(AppIcons.playStore.data, size: AppIcons.playStore.size),
              onTap: () {
                if (widget.packageId != null) {
                  openUri(
                    generatePlayStoreUriFromPackageId(widget.packageId!),
                  );
                }
              },
            ),
            AppListTile(
              dense: true,
              title: const Text('Copy package ID'),
              enabled: widget.packageId != null,
              subtitle: Text(widget.packageId ?? 'Not available'),
              leading:
                  Icon(AppIcons.clipboard.data, size: AppIcons.clipboard.size),
              onTap: () {
                if (widget.packageId != null) {
                  context.copyTextToClipboardAndShowToast(widget.packageId!);
                } else {
                  showToast(context, 'Package ID is not available');
                }
              },
            ),
            AppListTile(
              dense: true,
              title: const Text('Copy package name'),
              enabled: widget.packageName != null,
              subtitle: Text(widget.packageName ?? 'Not available'),
              leading: Icon(AppIcons.name.data, size: AppIcons.name.size),
              onTap: () {
                if (widget.packageName != null) {
                  context.copyTextToClipboardAndShowToast(widget.packageName!);
                } else {
                  showToast(context, 'Package name is not available');
                }
              },
            ),
            AppListTile(
              dense: true,
              title: const Text('Uninstall'),
              leading: Icon(
                AppIcons.delete.data,
                size: kDefaultIconSize,
                color: Colors.red,
              ),
              onTap: () {
                context.pop();
                perform(InstalledAppTileAction.uninstall);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pop() {
    if (context.canPop()) {
      context.pop();
    }
  }

  Widget _buildScaffoldWrapper(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pop(),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(.2),
        body: SizedBox.expand(
          child: DraggableScrollableSheet(
            builder: (
              BuildContext context,
              ScrollController scrollController,
            ) =>
                // Do not use [ColoredBox] here, it will block the ListTile from displaying the ink effect...
                Material(
              elevation: 10,
              color: context.theme.scaffoldBackgroundColor,
              child: SingleChildScrollView(
                controller: scrollController,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(k4dp).copyWith(top: 0),
      child: SizedBox(
        height: kToolbarHeight * 1.4,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            ActionButton(
              icon: AppIcons.download.data,
              iconSize: AppIcons.download.size,
              onTap: () {
                perform(InstalledAppTileAction.extract);
              },
              text: 'Extract',
              tooltip: 'Extract apk',
            ),
            ActionButton(
              icon: AppIcons.share.data,
              iconSize: AppIcons.share.size,
              onTap: () {
                perform(InstalledAppTileAction.share);
              },
              text: 'Share',
              tooltip: 'Share apk',
            ),
            ActionButton(
              icon: AppIcons.externalLink.data,
              iconSize: AppIcons.externalLink.size,
              onTap: () {
                perform(InstalledAppTileAction.open);
              },
              text: 'Open app',
              tooltip: 'Open app',
            ),
            ActionButton(
              icon: AppIcons.settings.data,
              iconSize: AppIcons.settings.size,
              onTap: () {
                perform(InstalledAppTileAction.openSettings);
              },
              text: 'Settings',
              tooltip: 'Open app settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageThumbnailHeader() {
    return AppListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: k8dp,
        horizontal: k8dp,
      ),
      leading: widget.iconUri != null
          ? PackageImageUri(
              fetchThumbnail: widget.fetchIconUriAsThumbnail,
              uri: widget.iconUri,
            )
          : PackageImageBytes(icon: widget.iconBytes),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
    );
  }

  Widget _buildDragMeIndicator() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: k4dp),
        width: kToolbarHeight / 2,
        height: _dragIndicatorWidth * 2 + _dragIndicatorWidth * 2,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: context.theme.disabledColor,
              width: _dragIndicatorWidth,
            ),
            bottom: BorderSide(
              color: context.theme.disabledColor,
              width: _dragIndicatorWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.text,
    required this.tooltip,
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  final String text;
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AppIconButton(
        onTap: onTap,
        icon: SizedBox(
          height: kToolbarHeight,
          width: kToolbarHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: iconSize,
                color: context.theme.textTheme.labelSmall!.color,
              ),
              Text(text),
            ],
          ),
        ),
        tooltip: tooltip,
      ),
    );
  }
}
