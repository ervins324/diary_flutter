/// Bell slot model corresponding to backend BellSlotRead schema.
class BellSlotModel {
  final String id;
  final int lessonOrder;
  final String startTime;
  final String endTime;
  final String? name;

  const BellSlotModel({
    required this.id,
    required this.lessonOrder,
    required this.startTime,
    required this.endTime,
    this.name,
  });

  /// Formats time strings like "08:30:00" to "08:30"
  static String formatTime(String timeStr) {
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  factory BellSlotModel.fromJson(Map<String, dynamic> json) {
    return BellSlotModel(
      id: json['id']?.toString() ?? '',
      lessonOrder: (json['lesson_order'] as num?)?.toInt() ?? 1,
      startTime: formatTime(json['start_time'] as String? ?? '08:30'),
      endTime: formatTime(json['end_time'] as String? ?? '09:15'),
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_order': lessonOrder,
      'start_time': startTime,
      'end_time': endTime,
      'name': name,
    };
  }
}
