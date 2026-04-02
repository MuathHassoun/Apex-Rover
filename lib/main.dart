import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/navigation_screen.dart';
import 'config/theme.dart';

void main() {
  runApp(const ProviderScope(child: ApexRoverControlApp()));
}

class ApexRoverControlApp extends StatelessWidget {
  const ApexRoverControlApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apex Rover Control',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const NavigationScreen(),
    );
  }
}
