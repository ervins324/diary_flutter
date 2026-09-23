/// Offline queued action for background synchronization with the Docker server.
class SyncAction {
  final String id;
  final String actionType;
  final String endpoint;
  final String httpMethod; // 'POST' | 'PUT' | 'PATCH' | 'DELETE'
  final Map<String, dynamic> payload;
  final List<String> localFilePaths; // Files staged for /api/v1/files/upload
  final String createdAt;
  final int retryCount;

  const SyncAction({
    required this.id,
    required this.actionType,
    required this.endpoint,
    required this.httpMethod,
    required this.payload,
    this.localFilePaths = const [],
    required this.createdAt,
    this.retryCount = 0,
  });

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    var rawFiles = json['localFilePaths'];
    List<String> parsedFiles = [];
    if (rawFiles is List) {
      parsedFiles = rawFiles.map((f) => f.toString()).toList();
    }

    return SyncAction(
      id: json['id']?.toString() ?? '',
      actionType: json['actionType']?.toString() ?? '',
      endpoint: json['endpoint']?.toString() ?? '',
      httpMethod: json['httpMethod']?.toString() ?? 'POST',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      localFilePaths: parsedFiles,
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType,
      'endpoint': endpoint,
      'httpMethod': httpMethod,
      'payload': payload,
      'localFilePaths': localFilePaths,
      'createdAt': createdAt,
      'retryCount': retryCount,
    };
  }

  SyncAction copyWith({
    String? id,
    String? actionType,
    String? endpoint,
    String? httpMethod,
    Map<String, dynamic>? payload,
    List<String>? localFilePaths,
    String? createdAt,
    int? retryCount,
  }) {
    return SyncAction(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      payload: payload ?? this.payload,
      localFilePaths: localFilePaths ?? this.localFilePaths,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
