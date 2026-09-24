/// Subject model corresponding to backend SubjectRead schema.
class SubjectModel {
  final String id;
  final String name;
  final String shortName;
  final String colorHex;
  final String? defaultCabinet;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.colorHex,
    this.defaultCabinet,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
      colorHex: json['color_hex'] as String? ?? '#6366F1',
      defaultCabinet: json['default_cabinet'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'color_hex': colorHex,
      'default_cabinet': defaultCabinet,
    };
  }

  SubjectModel copyWith({
    String? id,
    String? name,
    String? shortName,
    String? colorHex,
    String? defaultCabinet,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      colorHex: colorHex ?? this.colorHex,
      defaultCabinet: defaultCabinet ?? this.defaultCabinet,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

