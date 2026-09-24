import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/liquid_theme.dart';
import '../../providers/notes_provider.dart';
import 'widgets/note_card.dart';
import 'widgets/note_form_dialog.dart';

/// Notes screen presenting searchable list of lesson notes.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesListProvider);
    final search = ref.watch(notesSearchProvider).toLowerCase();
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = notes.where((n) {
      if (search.isEmpty) return true;
      final subjectName = (n.subject?.name ?? '').toLowerCase();
      final text = n.text.toLowerCase();
      return subjectName.contains(search) || text.contains(search);
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
              builder: (_) => const NoteFormDialog(),
            );
          },
          backgroundColor: LiquidTheme.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notesListProvider.notifier).fetchRemote(),
        color: LiquidTheme.accent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (val) => ref.read(notesSearchProvider.notifier).state = val,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: loc.translate('search_notes'),
                    hintStyle: TextStyle(
                      color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: LiquidTheme.accentLight),
                    filled: true,
                    fillColor: isDark ? const Color(0x1F1E293B) : const Color(0x22CBD5E1),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 52,
                        color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.translate('no_notes'),
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
                    final note = filtered[index];
                    return NoteCard(key: ValueKey(note.id), note: note);
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
}
