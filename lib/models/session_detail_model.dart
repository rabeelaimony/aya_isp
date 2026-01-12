class SessionDetailResponse {
  final String? status;
  final String? message;
  final List<SessionEntry> sessions;
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;

  SessionDetailResponse({
    this.status,
    this.message,
    this.sessions = const [],
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
  });

  factory SessionDetailResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? rootData;
    List<dynamic> rawList = const [];

    if (json['data'] is Map<String, dynamic>) {
      rootData = json['data'] as Map<String, dynamic>;
      rawList = rootData['data'] as List<dynamic>? ?? const [];
    } else if (json['data'] is List) {
      rawList = json['data'] as List<dynamic>;
    }

    List<SessionEntry> parsedSessions = rawList
        .map((e) => SessionEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    int? _toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return SessionDetailResponse(
      status: json['status'] as String?,
      message: json['message'] as String?,
      sessions: parsedSessions,
      total: _toInt(rootData?['total'] ?? json['total']),
      perPage: _toInt(rootData?['per_page'] ?? json['per_page']),
      currentPage: _toInt(rootData?['current_page'] ?? json['current_page']),
      lastPage: _toInt(rootData?['last_page'] ?? json['last_page']),
    );
  }
}

class SessionEntry {
  final String? id;
  final DateTime? startTime;
  final DateTime? stopTime;
  final int? trafficBytes;
  final int? sessionSeconds;

  SessionEntry({
    this.id,
    this.startTime,
    this.stopTime,
    this.trafficBytes,
    this.sessionSeconds,
  });

  factory SessionEntry.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    int? _toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return SessionEntry(
      id: json['acctuniqueid']?.toString(),
      startTime: _parseDate(json['acctstarttime']),
      stopTime: _parseDate(json['acctstoptime']),
      trafficBytes: _toInt(json['traffic']),
      sessionSeconds: _toInt(json['sessiontime']),
    );
  }
}
