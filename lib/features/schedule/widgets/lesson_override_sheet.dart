import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/schedule_model.dart';
import '../../../models/subject_model.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/subjects_provider.dart';
import 'lesson_slot_card.dart';

/// Modal bottom sheet allowing users to change lessons, substitute subjects,
/// set academic event tags, and mark lessons as cancelled due to air alerts or schedule gaps.
class LessonOverrideSheet extends ConsumerStatefulWidget {
  final LessonSlot lesson;

  const LessonOverrideSheet({super.key, required this.lesson});

  @override
  ConsumerState<LessonOverrideSheet> createState() =>
      _LessonOverrideSheetState();
}

class _LessonOverrideSheetState extends ConsumerState<LessonOverrideSheet> {
  late final TextEditingController _cabinetController;
  late final TextEditingController _noteController;
  late final TextEditingController _searchController;

  late String _selectedSubjectId;
  late bool _isCancelled;
  late String? _eventType;
  bool _isSaving = false;
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _eventTypesConfig = [
    {
      'id': null,
      'labelUk': 'Звичайний',
      'labelEn': 'Regular',
      'icon': '🎓',
      'color': Color(0xFF64748B),
    },
    {
      'id': 'control_work',
      'labelUk': 'Контрольна',
      'labelEn': 'Control Work',
      'icon': '🔥',
      'color': Color(0xFFF43F5E),
    },
    {
      'id': 'test',
      'labelUk': 'Тест',
      'labelEn': 'Test / Quiz',
      'icon': '📝',
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'essay',
      'labelUk': 'Твір / Есе',
      'labelEn': 'Essay',
      'icon': '✍️',
      'color': Color(0xFFA855F7),
    },
    {
      'id': 'project',
      'labelUk': 'Проєкт',
      'labelEn': 'Project',
      'icon': '🚀',
      'color': Color(0xFF0EA5E9),
    },
    {
      'id': 'consultation',
      'labelUk': 'Консультація',
      'labelEn': 'Consultation',
      'icon': '💬',
      'color': Color(0xFF6366F1),
    },
  ];

  @override
  void initState() {
    super.initState();
    _cabinetController = TextEditingController(
      text: widget.lesson.cabinet ?? '',
    );
    _noteController = TextEditingController(
      text: widget.lesson.overrideNote ?? '',
    );
    _searchController = TextEditingController();

    _selectedSubjectId = widget.lesson.subject.id.isNotEmpty
        ? widget.lesson.subject.id
        : (widget.lesson.originalSubject?.id ?? '');
    _isCancelled = widget.lesson.isCancelled;
    _eventType = widget.lesson.eventType;
  }

  @override
  void dispose() {
    _cabinetController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isAirAlertNote(String text) {
    final lower = text.toLowerCase();
    return lower.contains('тривог') || lower.contains('alert');
  }

  bool _isConsultationSkipNote(String text) {
    final lower = text.toLowerCase();
    return lower.contains('пропущ') || lower.contains('skip');
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final loc = AppLocalizations.of(context);
    final origSubj = widget.lesson.originalSubject ?? widget.lesson.subject;

    final cleanSubjectId = !_isCancelled && _selectedSubjectId.isNotEmpty
        ? _selectedSubjectId
        : (origSubj.id.isNotEmpty ? origSubj.id : null);

    final payload = <String, dynamic>{
      'date': widget.lesson.date,
      'lesson_order': widget.lesson.lessonOrder,
      'subject_id': _isCancelled ? null : cleanSubjectId,
      'original_subject_id': origSubj.id.isNotEmpty ? origSubj.id : null,
      'original_subject_name': origSubj.name.isNotEmpty ? origSubj.name : null,
      'cabinet': _isCancelled
          ? null
          : (_cabinetController.text.trim().isEmpty
                ? null
                : _cabinetController.text.trim()),
      'is_cancelled': _isCancelled,
      'note': _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      'event_type': _eventType,
    };

    try {
      await ref.read(scheduleProvider.notifier).setOverride(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('lesson_override_saved')),
            duration: const Duration(seconds: 2),
            backgroundColor: LiquidTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving override: $e'),
            backgroundColor: LiquidTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleReset() async {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? LiquidTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.translate('reset_to_regular'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          loc.translate('reset_confirm'),
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              loc.translate('cancel'),
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: LiquidTheme.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              loc.translate('reset_to_regular'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(scheduleProvider.notifier)
            .deleteOverride(widget.lesson.date, widget.lesson.lessonOrder);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('lesson_override_deleted')),
              duration: const Duration(seconds: 2),
              backgroundColor: LiquidTheme.accentLight,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting override: $e'),
              backgroundColor: LiquidTheme.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUk = loc.locale.languageCode == 'uk';
    final subjects = ref.watch(subjectsProvider);

    final origSubj = widget.lesson.originalSubject ?? widget.lesson.subject;

    // Filtered subjects for substitution list
    final filteredSubjects = subjects.where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.shortName.toLowerCase().contains(q);
    }).toList();

    // Active chosen subject
    SubjectModel? currentChosenSubject;
    for (final s in subjects) {
      if (s.id == _selectedSubjectId) {
        currentChosenSubject = s;
        break;
      }
    }
    currentChosenSubject ??= origSubj;

    final isAirAlertActive =
        _isCancelled && _isAirAlertNote(_noteController.text);
    final isConsultationSkipActive =
        _isCancelled && _isConsultationSkipNote(_noteController.text);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xEE0B1120) : const Color(0xEEF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x4094A3B8)
                    : const Color(0x4064748B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: LiquidTheme.accentLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: LiquidTheme.accentLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('change_lesson'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${widget.lesson.date} • #${widget.lesson.lessonOrder} (${widget.lesson.startTime} - ${widget.lesson.endTime})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? LiquidTheme.darkTextMuted
                            : LiquidTheme.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: isDark
                    ? LiquidTheme.darkTextMuted
                    : LiquidTheme.lightTextMuted,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable form body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Academic Event Types ───────────────────────
                  Text(
                    loc.translate('academic_event').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark
                          ? LiquidTheme.darkTextMuted
                          : LiquidTheme.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _eventTypesConfig.map((et) {
                      final isSelected = _eventType == et['id'];
                      final color = et['color'] as Color;
                      final label = isUk ? et['labelUk'] : et['labelEn'];
                      final icon = et['icon'] as String;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _eventType = et['id'] as String?;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.18)
                                : (isDark
                                      ? const Color(0x1F334155)
                                      : const Color(0x1FE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : (isDark
                                        ? LiquidTheme.darkBorder
                                        : LiquidTheme.lightBorder),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? color
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Quick Consultation Skip (if applicable) ────
                  if (widget.lesson.isConsultation ||
                      _eventType == 'consultation') ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isConsultationSkipActive) {
                            _isCancelled = false;
                            _noteController.text = '';
                          } else {
                            _isCancelled = true;
                            _noteController.text = isUk
                                ? 'Пропущено консультацію'
                                : 'Skipped consultation';
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isConsultationSkipActive
                              ? const Color(0x226366F1)
                              : (isDark
                                    ? const Color(0x1F334155)
                                    : const Color(0x1FE2E8F0)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isConsultationSkipActive
                                ? const Color(0xFF6366F1)
                                : (isDark
                                      ? LiquidTheme.darkBorder
                                      : LiquidTheme.lightBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('💬', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.translate('consultation_skip'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isConsultationSkipActive
                                          ? const Color(0xFF818CF8)
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                    ),
                                  ),
                                  Text(
                                    loc.translate('consultation_skip_desc'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? LiquidTheme.darkTextMuted
                                          : LiquidTheme.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isConsultationSkipActive
                                    ? const Color(0xFF6366F1)
                                    : (isDark
                                          ? const Color(0x33475569)
                                          : const Color(0x33CBD5E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isConsultationSkipActive
                                    ? (isUk ? 'Пропущено' : 'Skipped')
                                    : (isUk ? 'Пропустити' : 'Skip'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isConsultationSkipActive
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Quick Air Alert Cancellation Button ────────
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isAirAlertActive) {
                          _isCancelled = false;
                          _noteController.text = '';
                        } else {
                          _isCancelled = true;
                          _noteController.text = isUk
                              ? 'Повітряна тривога'
                              : 'Air raid alert';
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAirAlertActive
                            ? LiquidTheme.danger.withValues(alpha: 0.15)
                            : (isDark
                                  ? const Color(0x1F334155)
                                  : const Color(0x1FE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isAirAlertActive
                              ? LiquidTheme.danger
                              : (isDark
                                    ? LiquidTheme.darkBorder
                                    : LiquidTheme.lightBorder),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🚨', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.translate('air_alert_cancel'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isAirAlertActive
                                        ? LiquidTheme.danger
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                  ),
                                ),
                                Text(
                                  loc.translate('air_alert_cancel_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? LiquidTheme.darkTextMuted
                                        : LiquidTheme.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAirAlertActive
                                  ? LiquidTheme.danger
                                  : (isDark
                                        ? const Color(0x33475569)
                                        : const Color(0x33CBD5E1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAirAlertActive
                                  ? (isUk ? 'Скасовано' : 'Cancelled')
                                  : (isUk ? 'Скасувати' : 'Cancel'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAirAlertActive
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Cancel Lesson Toggle ───────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x1F334155)
                          : const Color(0x1FE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? LiquidTheme.darkBorder
                            : LiquidTheme.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('cancel_lesson'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                loc.translate('cancel_lesson_desc'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? LiquidTheme.darkTextMuted
                                      : LiquidTheme.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isCancelled,
                          activeThumbColor: LiquidTheme.danger,
                          onChanged: (val) {
                            setState(() {
                              _isCancelled = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Substitute Subject Picker (when not cancelled) ──
                  if (!_isCancelled) ...[
                    Text(
                      loc.translate('substitute_subject').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark
                            ? LiquidTheme.darkTextMuted
                            : LiquidTheme.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: loc.translate('search_subject'),
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? LiquidTheme.darkTextMuted
                              : LiquidTheme.lightTextMuted,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0x1F334155)
                            : const Color(0x1FE2E8F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? LiquidTheme.darkBorder
                                : LiquidTheme.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? LiquidTheme.darkBorder
                                : LiquidTheme.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: LiquidTheme.accentLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subjects list
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x1F1E293B)
                            : const Color(0x1FE2E8F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? LiquidTheme.darkBorder
                              : LiquidTheme.lightBorder,
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filteredSubjects.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0x1F475569)
                              : const Color(0x1FCBD5E1),
                        ),
                        itemBuilder: (context, idx) {
                          final subj = filteredSubjects[idx];
                          final isSelected = subj.id == _selectedSubjectId;
                          final color = parseHexColor(subj.colorHex);

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              subj.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? LiquidTheme.accentLight
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: LiquidTheme.accentLight,
                                    size: 18,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedSubjectId = subj.id;
                                if (subj.defaultCabinet != null &&
                                    subj.defaultCabinet!.isNotEmpty &&
                                    _cabinetController.text.trim().isEmpty) {
                                  _cabinetController.text =
                                      subj.defaultCabinet!;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cabinet text field
                    Text(
                      loc.translate('cab').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark
                            ? LiquidTheme.darkTextMuted
                            : LiquidTheme.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cabinetController,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 204 or Lab 1',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? LiquidTheme.darkTextMuted
                              : LiquidTheme.lightTextMuted,
                        ),
                        prefixIcon: const Icon(Icons.room_rounded, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0x1F334155)
                            : const Color(0x1FE2E8F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? LiquidTheme.darkBorder
                                : LiquidTheme.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? LiquidTheme.darkBorder
                                : LiquidTheme.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: LiquidTheme.accentLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Note / Reason field ────────────────────────
                  Text(
                    loc.translate('override_note').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark
                          ? LiquidTheme.darkTextMuted
                          : LiquidTheme.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.translate('override_note_hint'),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? LiquidTheme.darkTextMuted
                            : LiquidTheme.lightTextMuted,
                      ),
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0x1F334155)
                          : const Color(0x1FE2E8F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? LiquidTheme.darkBorder
                              : LiquidTheme.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? LiquidTheme.darkBorder
                              : LiquidTheme.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: LiquidTheme.accentLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Diary Appearance Preview ───────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x1F1E293B)
                          : const Color(0x1FE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? LiquidTheme.darkBorder
                            : LiquidTheme.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('diary_preview'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? LiquidTheme.darkTextMuted
                                : LiquidTheme.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (_isCancelled) ...[
                              Text(
                                loc.translate('cancelled'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: LiquidTheme.danger,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              if (origSubj.name.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${origSubj.name})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? LiquidTheme.darkTextMuted
                                        : LiquidTheme.lightTextMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ] else ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: parseHexColor(
                                    currentChosenSubject.colorHex,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentChosenSubject.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (_cabinetController.text
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.translate('cab')} ${_cabinetController.text.trim()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? LiquidTheme.darkTextSecondary
                                        : LiquidTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom Action Buttons ──────────────────────────────
          if (widget.lesson.isOverride) ...[
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _handleReset,
              icon: const Icon(
                Icons.restore_rounded,
                size: 16,
                color: LiquidTheme.danger,
              ),
              label: Text(
                loc.translate('reset_to_regular'),
                style: const TextStyle(
                  color: LiquidTheme.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: LiquidTheme.danger.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    loc.translate('cancel'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: LiquidTheme.accentLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          loc.translate('save'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
