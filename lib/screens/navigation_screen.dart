import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import 'control_screen.dart';
import 'connection_screen.dart';
import 'about_screen.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  int _selectedIndex = 0;

  static const Color _bgColor = Color(0xFF020712);
  static const Color _panelColor = Color(0xFF07111F);
  static const Color _panelColor2 = Color(0xFF0D1B2E);
  static const Color _borderColor = Color(0xFF1E3858);
  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _mutedColor = Color(0xFF9AA8BA);

  final List<Widget> _screens = const [
    DashboardScreen(),
    ControlScreen(),
    ConnectionScreen(),
    AboutScreen(),
  ];

  final List<String> _screenTitles = const [
    'Home',
    'Control',
    'Connect',
    'About',
  ];

  final List<String> _screenSubtitles = const [
    'Apex Rover Dashboard',
    'Manual Robot Control',
    'ESP32 WebSocket Link',
    'Project Information',
  ];

  final List<IconData> _screenIcons = const [
    Icons.dashboard_rounded,
    Icons.gamepad_rounded,
    Icons.wifi_rounded,
    Icons.info_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bgColor,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_panelColor, _panelColor2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _cyanColor.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cyanColor.withValues(alpha: 0.10),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(
                _screenIcons[_selectedIndex],
                color: _cyanColor,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _screenTitles[_selectedIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _screenSubtitles[_selectedIndex],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _bgColor,
              _panelColor,
              Color(0xFF0B1626),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_panelColor, _panelColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _borderColor.withValues(alpha: 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _cyanColor.withValues(alpha: 0.08),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: List.generate(_screens.length, (index) {
              final selected = _selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected ? _cyanColor.withValues(alpha: 0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? _cyanColor.withValues(alpha: 0.45) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _screenIcons[index],
                          size: selected ? 26 : 23,
                          color: selected ? _cyanColor : _mutedColor,
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            color: selected ? _cyanColor : _mutedColor,
                            fontSize: selected ? 11 : 10,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          ),
                          child: Text(
                            _screenTitles[index],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
