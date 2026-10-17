import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class UndoInfo {
  const UndoInfo({
    required this.drinkIds,
    required this.name,
    required this.icon,
    required this.isRound,
  });

  final List<String> drinkIds;
  final String name;
  final String icon;
  final bool isRound;
}

/// 5-Sekunden-Undo-Toast mit Fortschrittsbalken.
class UndoToast extends StatefulWidget {
  const UndoToast({
    super.key,
    required this.info,
    required this.onUndo,
    required this.onDismiss,
  });

  final UndoInfo info;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;

  @override
  State<UndoToast> createState() => _UndoToastState();
}

class _UndoToastState extends State<UndoToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDismiss();
        })
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return PopIn(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161622),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: white(0.15)),
          boxShadow: [
            BoxShadow(
              color: black(0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  info.icon.isEmpty ? '🍺' : info.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${info.name} eingetragen',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(12, weight: FontWeight.w700),
                      ),
                      Text(
                        info.isRound ? 'Runde ausgegeben' : 'Gerade geloggt',
                        style: AppText.body(10, color: AppColors.dim),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Pressable(
                  onTap: widget.onUndo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pink.o(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        const Icon(
                          Icons.undo_rounded,
                          size: 14,
                          color: AppColors.pink,
                        ),
                        Text(
                          'Rückgängig',
                          style: AppText.body(
                            12,
                            color: AppColors.pink,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Container(
                height: 4,
                decoration: BoxDecoration(
                  color: white(0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                clipBehavior: Clip.antiAlias,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1 - _c.value,
                  child: const ColoredBox(color: AppColors.pink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
