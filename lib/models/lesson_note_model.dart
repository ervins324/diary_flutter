import 'subject_model.dart';
import 'homework_model.dart';

/// Lesson note model corresponding to backend LessonNoteRead schema.
class LessonNoteModel {
  final String id;
  final String subjectId;
  final String date; // YYYY-MM-DD
  final int lessonOrder;
  final String text;
  final List<String> images;
  final List<AttachmentItem> attachments;
  final String? createdAt;
  final String? updatedAt;
  final SubjectModel? subject;
  final bool isPendingSync;

  const LessonNoteModel({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.lessonOrder,
    required this.text,
    this.images = const [],
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
    this.subject,
    this.isPendingSync = false,
  });

  factory LessonNoteModel.fromJson(Map<String, dynamic> json) {
    var rawAttachments = json['attachments'];
    List<AttachmentItem> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments
          .map((a) => AttachmentItem.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();
    }

    var rawImages = json['images'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    }

    SubjectModel? parsedSubject;
    if (json['subject'] is Map) {
      parsedSubject = SubjectModel.fromJson(Map<String, dynamic>.from(json['subject'] as Map));
    }

    return LessonNoteModel(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      lessonOrder: (json['lesson_order'] as num?)?.toInt() ?? 1,
      text: json['text'] as String? ?? '',
      images: parsedImages,
      attachments: parsedAttachments,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      subject: parsedSubject,
      isPendingSync: json['isPendingSync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'date': date,
      'lesson_order': lessonOrder,
      'text': text,
      'images': images,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
      'subject': subject?.toJson(),
      'isPendingSync': isPendingSync,
    };
  }

  LessonNoteModel copyWith({
    String? id,
    String? subjectId,
    String? date,
    int? lessonOrder,
    String? text,
    List<String>? images,
    List<AttachmentItem>? attachments,
    String? createdAt,
    String? updatedAt,
    SubjectModel? subject,
    bool? isPendingSync,
  }) {
    return LessonNoteModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      lessonOrder: lessonOrder ?? this.lessonOrder,
      text: text ?? this.text,
      images: images ?? this.images,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subject: subject ?? this.subject,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }
}
