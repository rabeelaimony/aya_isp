class ExtendValidityResponse {
  final bool status;
  final String message;
  final dynamic data;

  ExtendValidityResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ExtendValidityResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final status = _parseStatus(rawStatus);
    final msg = (json['msg'] ?? json['message'] ?? '').toString().trim();

    return ExtendValidityResponse(
      status: status,
      message: msg.isNotEmpty
          ? msg
          : status
              ? 'تم تمديد الصلاحية بنجاح'
              : 'تعذر تنفيذ طلب التمديد',
      data: json['data'],
    );
  }

  static bool _parseStatus(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final lowered = raw.toString().toLowerCase();
    return lowered == 'true' ||
        lowered == 'success' ||
        lowered == 'ok' ||
        lowered == '1';
  }
}
