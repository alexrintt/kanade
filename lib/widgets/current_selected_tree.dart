import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/stringify_uri_location.dart';

class CurrentSelectedTree extends StatefulWidget
    implements PreferredSizeWidget {
  const CurrentSelectedTree({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight / 4);

  @override
  State<CurrentSelectedTree> createState() => _CurrentSelectedTreeState();
}

class _CurrentSelectedTreeState extends State<CurrentSelectedTree>
    with SettingsStoreMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsStore,
      builder: (BuildContext context, Widget? child) {
        return GestureDetector(
          onTap: () {
            settingsStore.requestExportLocation();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: k3dp,
              horizontal: k8dp,
            ),
            color: context.theme.canvasColor,
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.only(right: k6dp),
                      child: Icon(
                        AppIcons.folder.data,
                        size: kDefaultIconSize,
                        color: context.theme.primaryColor.withOpacity(.5),
                      ),
                    ),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  TextSpan(
                    text: settingsStore.exportLocation == null
                        ? context.strings.selectOutputFolder
                        : stringifyTreeUri(settingsStore.exportLocation),
                    style: context.textTheme.labelMedium!.copyWith(
                      color: context.theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
