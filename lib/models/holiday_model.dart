/// Holiday model corresponding to backend HolidayRead schema.
class HolidayModel {
  final String id;
  final String name;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD

  const HolidayModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}
