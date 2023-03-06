import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    hide Stepper, Step, StepperType, ControlsDetails, StepState;
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../stores/background_task_store.dart';
import '../stores/bottom_navigation_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_localization_strings.dart';
import '../utils/stringify_uri_location.dart';
import 'multi_animated_builder.dart';
import 'stepper.dart';

class StorageRequirementsProgressStepper extends StatefulWidget {
  const StorageRequirementsProgressStepper({super.key});

  @override
  State<StorageRequirementsProgressStepper> createState() =>
      _StorageRequirementsProgressStepperState();
}

class _StorageRequirementsProgressStepperState
    extends State<StorageRequirementsProgressStepper>
    with
        SettingsStoreMixin,
        BackgroundTaskStoreMixin,
        BottomNavigationStoreMixin {
  bool get _wasExportLocationChosen => settingsStore.exportLocation != null;
  bool get _extractedAtLeastOneApk => backgroundTaskStore.tasks.isNotEmpty;

  int get _currentStep {
    final List<bool> steps = <bool>[
      _wasExportLocationChosen,
      _extractedAtLeastOneApk,
    ];

    return steps
        .map((bool e) => e ? 1 : 0)
        .reduce((int value, int element) => value + element)
        .clamp(0, steps.length - 1);
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
      state: _currentStep > index ? StepState.complete : StepState.indexed,
    );
  }

  Widget _buildExportApkExplanationMessage() {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          // TODO: Add translation.
          const TextSpan(
            text:
                'The apk list will appear here, to get start try to click over a tile on the app list screen! It will create a new export job that will copy the app apk to the folder you chose.\n\n',
          ),
          TextSpan(
            // TODO: Add translation.
            text:
                '${stringifyTreeUri(settingsStore.exportLocation) ?? 'Not set.'}.',
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
      animations: <Listenable>[backgroundTaskStore, settingsStore],
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          height: context.height,
          child: Stepper(
            dividerColor: context.theme.disabledColor,
            indexedTextColor: context.isDark ? context.primaryColor : null,
            elevation: 0,
            controlsBuilder: _buildStepperControls,
            currentStep: _currentStep,
            stepIconBuilder:
                (BuildContext context, int index, StepState state) {
              if (state == StepState.complete) {
                return Icon(
                  Pixel.check,
                  color: context.scaffoldBackgroundColor,
                  size: k8dp,
                );
              }
              return null;
            },
            backgroundColor: context.theme.splashColor,
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
          ),
        );
      },
    );
  }
}