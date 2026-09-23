import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../models/bell_slot_model.dart';
import '../../providers/bells_provider.dart';

/// Modal sheet for managing school bell timetable.
class BellsSheet extends ConsumerWidget {
  const BellsSheet({super.key});

  void _showAddBellDialog(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final orderCtrl = TextEditingController(text: '1');
    final startCtrl = TextEditingController(text: '08:30');
    final endCtrl = TextEditingController(text: '09:15');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            loc.translate('add_bell'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: loc.translate('lesson_order'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: startCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: loc.translate('start_time'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: endCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: loc.translate('end_time'),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final order = int.tryParse(orderCtrl.text.trim()) ?? 1;
                final start = startCtrl.text.trim();
                final end = endCtrl.text.trim();

                final currentBells = ref.read(bellsProvider);
                final updated = [
                  ...currentBells.where((b) => b.lessonOrder != order),
                  BellSlotModel(
                    id: const Uuid().v4(),
                    lessonOrder: order,
                    startTime: start,
                    endTime: end,
                  ),
                ]..sort((a, b) => a.lessonOrder.compareTo(b.lessonOrder));

                ref.read(bellsProvider.notifier).saveBellsBulk(updated);
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: LiquidTheme.accent),
              child: Text(loc.translate('save'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bells = ref.watch(bellsProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xEE0B1120) : const Color(0xEEF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0x4094A3B8) : const Color(0x4064748B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('bells'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () => _showAddBellDialog(context, ref),
                icon: const Icon(Icons.add_circle_outline_rounded, color: LiquidTheme.accentLight, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: bells.length,
              itemBuilder: (context, index) {
                final b = bells[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x1F334155) : const Color(0x22CBD5E1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: LiquidTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${b.lessonOrder}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LiquidTheme.accentLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${b.startTime} - ${b.endTime}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
