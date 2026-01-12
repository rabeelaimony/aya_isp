class ExpandTrafficResponse {
  final String status;
  final String? message;
  final dynamic data;

  ExpandTrafficResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory ExpandTrafficResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final statusStr = rawStatus == null ? '' : rawStatus.toString();
    return ExpandTrafficResponse(
      status: statusStr,
      message: json['message']?.toString(),
      data: json['data'],
    );
  }

  bool get isSuccess {
    final normalized = status.toLowerCase();
    return normalized == 'success' ||
        normalized == 'true' ||
        normalized == '1' ||
        normalized == 'ok';
  }

  bool get isError {
    final normalized = status.toLowerCase();
    return normalized == 'error' ||
        normalized == 'false' ||
        normalized == '0';
  }
}
