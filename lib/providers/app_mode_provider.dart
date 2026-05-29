import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppControlMode {
  manual,
  automatic,
}

final appControlModeProvider =
    StateProvider<AppControlMode>((ref) => AppControlMode.manual);