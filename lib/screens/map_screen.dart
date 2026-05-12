
import 'package:flutter/material.dart';
import '../config/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedMode = 'manual';
  bool _isRecording = false;
  bool _isPlaying = false;
  final List<Offset> _path = [];
  Offset? _robotPosition;

  final List<Map<String, dynamic>> _savedMaps = [
    {
      'name': 'Room A',
      'date': '2026-04-01',
      'points': 24,
      'icon': Icons.meeting_room,
    },
    {
      'name': 'Corridor B',
      'date': '2026-04-02',
      'points': 48,
      'icon': Icons.linear_scale,
    },
    {
      'name': 'Lab Area',
      'date': '2026-04-02',
      'points': 36,
      'icon': Icons.science,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Mode Selector
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Map Mode', style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'manual',
                      icon: Icon(Icons.touch_app),
                      label: Text('Manual'),
                    ),
                    ButtonSegment(
                      value: 'record',
                      icon: Icon(Icons.fiber_manual_record),
                      label: Text('Record'),
                    ),
                    ButtonSegment(
                      value: 'auto',
                      icon: Icon(Icons.auto_fix_high),
                      label: Text('Auto'),
                    ),
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (val) =>
                      setState(() => _selectedMode = val.first),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Map Canvas
          Text('Live Map', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Grid Background
                CustomPaint(
                  painter: _GridPainter(),
                  child: Container(),
                ),

                // Robot Position
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.smart_toy,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
                        ),
                        child: Text(
                          'Robot Position',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? AppColors.error
                          : AppColors.success,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRecording
                              ? Icons.fiber_manual_record
                              : Icons.check_circle,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isRecording ? 'Recording' : 'Ready',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Coordinates
                Positioned(
                  bottom: AppSpacing.md,
                  left: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Text(
                      'X: 0.0  Y: 0.0',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Map Controls
         Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    Expanded(
      child: _MapButton(
        icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
        label: _isRecording ? 'Stop' : 'Record',
        color: _isRecording ? AppColors.error : AppColors.primary,
        onTap: () => setState(() => _isRecording = !_isRecording),
      ),
    ),
    Expanded(
      child: _MapButton(
        icon: _isPlaying ? Icons.pause : Icons.play_arrow,
        label: _isPlaying ? 'Pause' : 'Play',
        color: AppColors.success,
        onTap: () => setState(() => _isPlaying = !_isPlaying),
      ),
    ),
    Expanded(
      child: _MapButton(
        icon: Icons.refresh,
        label: 'Reset',
        color: AppColors.warning,
        onTap: () => setState(() {
          _path.clear();
          _isRecording = false;
          _isPlaying = false;
        }),
      ),
    ),
    Expanded(
      child: _MapButton(
        icon: Icons.save,
        label: 'Save',
        color: Colors.purple,
        onTap: () => _showSaveDialog(context),
      ),
    ),
  ],
),

          const SizedBox(height: AppSpacing.xl),

          // Saved Maps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Saved Maps', style: AppTextStyles.heading3),
              Text(
                '${_savedMaps.length} maps',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedMaps.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final map = _savedMaps[index];
              return _SavedMapCard(
                name: map['name'],
                date: map['date'],
                points: map['points'],
                icon: map['icon'],
                onPlay: () => setState(() => _isPlaying = true),
                onDelete: () => setState(
                  () => _savedMaps.removeAt(index),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Map'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Map Name',
            hintText: 'Enter map name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _savedMaps.add({
                    'name': controller.text,
                    'date': DateTime.now()
                        .toString()
                        .split(' ')[0],
                    'points': _path.length,
                    'icon': Icons.map,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Map saved: ${controller.text}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Grid Painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Map Control Button
class _MapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MapButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Saved Map Card
class _SavedMapCard extends StatelessWidget {
  final String name;
  final String date;
  final int points;
  final IconData icon;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _SavedMapCard({
    required this.name,
    required this.date,
    required this.points,
    required this.icon,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    '$date  •  $points points',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow, color: AppColors.success),
              onPressed: onPlay,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
