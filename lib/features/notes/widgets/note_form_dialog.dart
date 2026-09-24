import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/homework_model.dart';
import '../../../models/subject_model.dart';
import '../../../providers/notes_provider.dart';
import '../../../providers/subjects_provider.dart';
import '../../common/widgets/attachment_chips_view.dart';
import '../../common/widgets/lightbox_gallery.dart';

/// Modal bottom sheet to create or edit lesson notes.
class NoteFormDialog extends ConsumerStatefulWidget {
  final String? preselectedDate;
  final SubjectModel? preselectedSubject;
  final int? lessonOrder;

  const NoteFormDialog({
    super.key,
    this.preselectedDate,
    this.preselectedSubject,
    this.lessonOrder,
  });

  @override
  ConsumerState<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends ConsumerState<NoteFormDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _orderController;
  late DateTime _selectedDate;
  SubjectModel? _selectedSubject;
  final List<String> _stagedFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _orderController = TextEditingController(
      text: widget.lessonOrder != null ? widget.lessonOrder.toString() : '1',
    );

    if (widget.preselectedDate != null) {
      _selectedDate = DateTime.tryParse(widget.preselectedDate!) ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }

    _selectedSubject = widget.preselectedSubject;
  }

  @override
  void dispose() {
    _textController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(source: source, imageQuality: 85);
      if (xFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';
        final localFile = File('${appDir.path}/$fileName');
        await File(xFile.path).copy(localFile.path);

        setState(() {
          _stagedFiles.add(localFile.path);
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDocument() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
      );
      if (res.isNotEmpty && res.first.path != null) {
        final origin = File(res.first.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'note_doc_${DateTime.now().millisecondsSinceEpoch}_${res.first.name}';
        final localFile = File('${appDir.path}/$fileName');
        await origin.copy(localFile.path);

        setState(() {
          _stagedFiles.add(localFile.path);
        });
      }
    } catch (_) {}
  }

  void _submit() {
    final text = _textController.text.trim();
    final subjects = ref.read(subjectsProvider);
    final subjectToSave = _selectedSubject != null
        ? (subjects.where((s) => s.id == _selectedSubject!.id).firstOrNull ?? _selectedSubject)
        : (subjects.isNotEmpty ? subjects.first : null);
    if (text.isEmpty || subjectToSave == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final order = int.tryParse(_orderController.text.trim()) ?? 1;

    ref.read(notesListProvider.notifier).addNote(
          subjectId: subjectToSave.id,
          date: dateStr,
          lessonOrder: order,
          text: text,
          stagedLocalFiles: _stagedFiles,
          subject: subjectToSave,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Safely resolve the selected subject against the available subjects list
    final currentSubject = _selectedSubject != null && subjects.isNotEmpty
        ? (subjects.where((s) => s.id == _selectedSubject!.id).firstOrNull ??
            subjects.first)
        : (subjects.isNotEmpty ? subjects.first : null);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xEE0B1120) : const Color(0xEEF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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

            Text(
              loc.translate('add_note'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Subject dropdown
            DropdownButtonFormField<SubjectModel>(
              initialValue: currentSubject,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              decoration: InputDecoration(
                labelText: loc.translate('subjects'),
                labelStyle: TextStyle(
                  color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                ),
                filled: true,
                fillColor: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: subjects.map((s) {
                return DropdownMenuItem<SubjectModel>(
                  value: s,
                  child: Text(
                    s.name,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedSubject = val),
            ),
            const SizedBox(height: 12),

            // Date & Order
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2028),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: LiquidTheme.accentLight),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy-MM-dd').format(_selectedDate),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _orderController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: '#',
                      labelStyle: TextStyle(
                        color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Note text
            TextField(
              controller: _textController,
              maxLines: 4,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: loc.translate('note_text'),
                hintStyle: TextStyle(
                  color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                ),
                filled: true,
                fillColor: isDark ? const Color(0x1F334155) : const Color(0x22E2E8F0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),

            // Staged photos & attachments with tap-to-zoom
            if (_stagedFiles.isNotEmpty) ...[
              AttachmentChipsView(
                images: _stagedFiles
                    .where((p) => AttachmentHelper.isImageAttachment('image', p))
                    .toList(),
                attachments: _stagedFiles
                    .where((p) => !AttachmentHelper.isImageAttachment('image', p))
                    .map((p) => AttachmentItem(
                          name: p.split(Platform.pathSeparator).last,
                          type: p.toLowerCase().endsWith('.pdf') ? 'pdf' : 'presentation',
                          url: p,
                          localFilePath: p,
                        ))
                    .toList(),
                isDark: isDark,
                onRemoveImage: (idx) {
                  final imgList = _stagedFiles
                      .where((p) => AttachmentHelper.isImageAttachment('image', p))
                      .toList();
                  final target = imgList[idx];
                  setState(() => _stagedFiles.remove(target));
                },
                onRemoveAttachment: (idx) {
                  final docList = _stagedFiles
                      .where((p) => !AttachmentHelper.isImageAttachment('image', p))
                      .toList();
                  final target = docList[idx];
                  setState(() => _stagedFiles.remove(target));
                },
              ),
              const SizedBox(height: 12),
            ],

            // Photo and file picker buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: Text(loc.translate('camera')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LiquidTheme.accentLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: Text(loc.translate('gallery')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LiquidTheme.accentLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickDocument,
                  icon: const Icon(Icons.attach_file_rounded),
                  color: LiquidTheme.accentLight,
                  tooltip: 'Attach document',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: LiquidTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                loc.translate('save'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
