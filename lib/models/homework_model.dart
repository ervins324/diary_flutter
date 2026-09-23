import 'subject_model.dart';

/// Attachment item metadata corresponding to backend AttachmentItem.
class AttachmentItem {
  final String? id;
  final String name;
  final String type; // 'image' | 'pdf' | 'presentation' | 'link'
  final String url;
  final int? size;
  final String? localFilePath; // Staged local path for offline uploads

  const AttachmentItem({
    this.id,
    required this.name,
    required this.type,
    required this.url,
    this.size,
    this.localFilePath,
  });

  factory AttachmentItem.fromJson(Map<String, dynamic> json) {
    return AttachmentItem(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? 'file',
      type: json['type'] as String? ?? 'image',
      url: json['url'] as String? ?? '',
      size: (json['size'] as num?)?.toInt(),
      localFilePath: json['localFilePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'size': size,
      'localFilePath': localFilePath,
    };
  }
}

/// Homework item model with offline sync tracking.
class HomeworkItem {
  final String id;
  final String subjectId;
  final String dueDate; // YYYY-MM-DD
  final int? lessonOrder;
  final String text;
  final bool isCompleted;
  final bool isFailed;
  final List<String> images;
  final List<AttachmentItem> attachments;
  final int timeSpentSeconds;
  final String? assignedDate;
  final String? createdAt;
  final SubjectModel? subject;
  final bool isPendingSync; // Local flag for offline queue

  const HomeworkItem({
    required this.id,
    required this.subjectId,
    required this.dueDate,
    this.lessonOrder,
    required this.text,
    this.isCompleted = false,
    this.isFailed = false,
    this.images = const [],
    this.attachments = const [],
    this.timeSpentSeconds = 0,
    this.assignedDate,
    this.createdAt,
    this.subject,
    this.isPendingSync = false,
  });

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
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

    return HomeworkItem(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      lessonOrder: (json['lesson_order'] as num?)?.toInt(),
      text: json['text'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      isFailed: json['is_failed'] as bool? ?? false,
      images: parsedImages,
      attachments: parsedAttachments,
      timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt() ?? 0,
      assignedDate: json['assigned_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      subject: parsedSubject,
      isPendingSync: json['isPendingSync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'due_date': dueDate,
      'lesson_order': lessonOrder,
      'text': text,
      'is_completed': isCompleted,
      'is_failed': isFailed,
      'images': images,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'time_spent_seconds': timeSpentSeconds,
      'assigned_date': assignedDate,
      'created_at': createdAt,
      'subject': subject?.toJson(),
      'isPendingSync': isPendingSync,
    };
  }

  HomeworkItem copyWith({
    String? id,
    String? subjectId,
    String? dueDate,
    int? lessonOrder,
    String? text,
    bool? isCompleted,
    bool? isFailed,
    List<String>? images,
    List<AttachmentItem>? attachments,
    int? timeSpentSeconds,
    String? assignedDate,
    String? createdAt,
    SubjectModel? subject,
    bool? isPendingSync,
  }) {
    return HomeworkItem(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      dueDate: dueDate ?? this.dueDate,
      lessonOrder: lessonOrder ?? this.lessonOrder,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      images: images ?? this.images,
      attachments: attachments ?? this.attachments,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      assignedDate: assignedDate ?? this.assignedDate,
      createdAt: createdAt ?? this.createdAt,
      subject: subject ?? this.subject,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }
}
