import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    hide ControlsDetails, Step, StepState, Stepper, StepperType;
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/background_task_store.dart';
import '../stores/bottom_navigation_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
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
      icon: Icon(icon, size: kDefaultIconSize),
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
            AppIcons.folder.data,
            onPressed: settingsStore.requestExportLocation,
          ),
        );
      case 1:
      default:
        child = Wrap(
          children: <Widget>[
            _buildFilledButton(
              context.strings.goToAppList,
              AppIcons.apps.data,
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
              child: Text(context.strings.resetFolder),
            ),
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
          TextSpan(
            text: '${context.strings.exportApkExplanationMessage}\n\n',
          ),
          TextSpan(
            text:
                '${stringifyTreeUri(settingsStore.exportLocation) ?? context.strings.notSet}.',
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
      context.strings.storagePermissionExplanationMessage,
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
            controlsBuilder: _buildStepperControls,
            currentStep: _currentStep,
            stepIconBuilder:
                (BuildContext context, int index, StepState state) {
              if (state == StepState.complete) {
                return Icon(
                  AppIcons.checkmark.data,
                  color: context.scaffoldBackgroundColor,
                  size: kDefaultIconSize,
                );
              }
              return null;
            },
            steps: <Step>[
              _createStep(
                title: context.strings.selectOutputFolder,
                index: 0,
                child: _buildPermissionExplanationMessage(),
              ),
              _createStep(
                title: context.strings.exportApk,
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
