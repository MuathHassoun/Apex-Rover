import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnoMotionSettings {
  final int stepperSteps;
  final int servoAngleStep;

  const UnoMotionSettings({
    required this.stepperSteps,
    required this.servoAngleStep,
  });

  UnoMotionSettings copyWith({
    int? stepperSteps,
    int? servoAngleStep,
  }) {
    return UnoMotionSettings(
      stepperSteps: stepperSteps ?? this.stepperSteps,
      servoAngleStep: servoAngleStep ?? this.servoAngleStep,
    );
  }
}

class UnoMotionSettingsNotifier extends StateNotifier<UnoMotionSettings> {
  UnoMotionSettingsNotifier()
      : super(
          const UnoMotionSettings(
            stepperSteps: 100,
            servoAngleStep: 5,
          ),
        );

  void setStepperSteps(int value) {
    state = state.copyWith(
      stepperSteps: value.clamp(1, 50000),
    );
  }

  void setServoAngleStep(int value) {
    state = state.copyWith(
      servoAngleStep: value.clamp(1, 30),
    );
  }
}

final unoMotionSettingsProvider =
    StateNotifierProvider<UnoMotionSettingsNotifier, UnoMotionSettings>((ref) {
  return UnoMotionSettingsNotifier();
});