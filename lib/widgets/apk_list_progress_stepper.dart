import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../stores/apk_list_store.dart';
import '../stores/bottom_navigation.dart';
import '../stores/settings.dart';
import '../utils/app_localization_strings.dart';
import '../utils/stringify_uri_location.dart';
import 'multi_animated_builder.dart';

class ApkListProgressStepper extends StatefulWidget {
  const ApkListProgressStepper({super.key});

  @override
  State<ApkListProgressStepper> createState() => _ApkListProgressStepperState();
}

class _ApkListProgressStepperState extends State<ApkListProgressStepper>
    with SettingsStoreMixin, ApkListStoreMixin, BottomNavigationStoreMixin {
  bool get _wasExportLocationChosen => settingsStore.exportLocation != null;
  bool get _extractedAtLeastOneApk => apkListStore.files.isNotEmpty;

  int get _currentStep {
    final List<bool> steps = <bool>[
      _wasExportLocationChosen,
      _extractedAtLeastOneApk,
    ];

    return steps
        .map((bool e) => e ? 1 : 0)
        .reduce((int value, int element) => value + element);
  }

  Widget _buildFilledButton(
    String text,
    IconData icon, {
    required VoidCallback onPressed,
  }) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        foregroundColor: context.scaffoldBackgroundColor,
        side: BorderSide(color: context.primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(k20dp),
        ),
      ),
      onPressed: onPressed,
      label: Text(text),
      icon: Icon(icon),
    );
  }

  Widget _buildStepperControls(BuildContext context, ControlsDetails details) {
    Widget child;

    switch (details.currentStep) {
      case 0:
        child = Align(
          alignment: Alignment.centerLeft,
          child: _buildFilledButton(
            context.strings.selectOutputFolder,
            Pixel.folder,
            onPressed: settingsStore.requestExportLocation,
          ),
        );
        break;
      case 1:
      default:
        child = Row(
          children: <Widget>[
            _buildFilledButton(
              // TODO: Add translation.
              'Go to app list',
              Pixel.home,
              onPressed: bottomNavigationStore.navigateToAppList,
            ),
            const Padding(padding: EdgeInsets.all(k2dp)),
            TextButton(
              onPressed: settingsStore.reset,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(k20dp),
                ),
              ),
              // TODO: Add translation.
              child: const Text('Reset folder'),
            )
          ],
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: k8dp),
      child: child,
    );
  }

  Step _createStep({
    required String title,
    required Widget child,
    required int index,
  }) {
    return Step(
      isActive: _currentStep > index,
      title: Text(title),
      content: child,
    );
  }

  Widget _buildExportApkExplanationMessage() {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          // TODO: Add translation.
          const TextSpan(
            text:
                'The apk list will appear here, to get started try to click over a tile on the app list screen! It will create a new export job that will copy the app apk to the folder you chose, you can also ',
          ),
          TextSpan(
            // TODO: Add translation.
            text:
                'modify your current export location ${stringifyTreeUri(settingsStore.exportLocation) ?? 'which is not set yet.'}.',
            recognizer: TapGestureRecognizer()
              ..onTap = settingsStore.requestExportLocation,
            style: context.textTheme.labelLarge!.copyWith(
              color: context.primaryColor,
            ),
          ),
        ],
      ),
      style: context.isDark
          ? TextStyle(color: context.theme.disabledColor)
          : TextStyle(
              color: context.theme.disabledColor.withOpacity(.3),
            ),
    );
  }

  Widget _buildPermissionExplanationMessage() {
    return Text(
      'To extract the apks this app needs access permission to a folder. It is recommended to select an empty folder or create a new one. It is also important to not select folders that are reserved by the system, such as the Android or Downloads folder.',
      style: context.isDark
          ? TextStyle(color: context.theme.disabledColor)
          : TextStyle(
              color: context.theme.disabledColor.withOpacity(.3),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiAnimatedBuilder(
      animations: <Listenable>[apkListStore, settingsStore],
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          height: context.height,
          child: Stepper(
            elevation: 0,
            controlsBuilder: _buildStepperControls,
            currentStep: _currentStep,
            steps: <Step>[
              _createStep(
                title: context.strings.selectOutputFolder,
                index: 0,
                child: _buildPermissionExplanationMessage(),
              ),
              _createStep(
                title: 'Export apk',
                index: 1,
                child: _buildExportApkExplanationMessage(),
              ),
            ],
            type: StepperType.horizontal,
          ),
        );
      },
    );
  }
}
