import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../providers/homework_provider.dart';
import 'widgets/homework_card.dart';
import 'widgets/homework_form_dialog.dart';

/// Homework management tab with status filters, study timer, and offline creation.
class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkList = ref.watch(homeworkListProvider);
    final activeFilter = ref.watch(homeworkFilterProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter items
    final filtered = homeworkList.where((h) {
      if (activeFilter == 'pending') return !h.isCompleted && !h.isFailed;
      if (activeFilter == 'completed') return h.isCompleted;
      if (activeFilter == 'failed') return h.isFailed;
      return true; // 'all'
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const HomeworkFormDialog(),
            );
          },
          backgroundColor: LiquidTheme.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeworkListProvider.notifier).fetchRemote(),
        color: LiquidTheme.accent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Filter chips header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(context, ref, 'pending', loc.translate('pending'), activeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, ref, 'completed', loc.translate('completed'), activeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, ref, 'failed', loc.translate('failed'), activeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, ref, 'all', loc.translate('all'), activeFilter),
                    ],
                  ),
                ),
              ),
            ),

            // Empty state or list
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 52,
                        color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.translate('no_homework'),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return HomeworkCard(key: ValueKey(item.id), item: item);
                  },
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String filterKey,
    String label,
    String activeFilter,
  ) {
    final isSelected = activeFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      selectedColor: LiquidTheme.accent,
      backgroundColor: isDark ? const Color(0x26334155) : const Color(0x33CBD5E1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) {
        ref.read(homeworkFilterProvider.notifier).state = filterKey;
      },
    );
  }
}
