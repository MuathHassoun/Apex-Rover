import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'control_screen.dart';
import 'sensors_screen.dart';
import 'connection_screen.dart';
import 'system_screen.dart';
import 'about_screen.dart';
import 'map_screen.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ControlScreen(),
    const SensorsScreen(),
    const ConnectionScreen(),
    const MapScreen(),
    const SystemScreen(),
    const AboutScreen(),
  ];

  final List<String> _screenTitles = [
    'Home',
    'Control',
    'Sensors',
    'Connect',
    'Map',
    'System',
    'About',
  ];

  final List<IconData> _screenIcons = [
    Icons.dashboard,
    Icons.gamepad,
    Icons.sensors,
    Icons.wifi,
    Icons.map,
    Icons.settings,
    Icons.info,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        elevation: 2,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
  selectedIndex: _selectedIndex,
  height: 60,
  onDestinationSelected: (int index) {
    setState(() {
      _selectedIndex = index;
    });
  },
  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
  destinations: List<NavigationDestination>.generate(
    _screens.length,
    (int index) {
      return NavigationDestination(
        icon: Icon(_screenIcons[index], size: 22),
        label: '',
      );
    },
  ),
),
    );
  }
}
