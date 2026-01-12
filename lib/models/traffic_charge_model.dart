class TrafficChargeResponse {
  final String status; // "success" أو "error"
  final String? message; // رسالة الخطأ أو null
  final String? typeError; // رقم نوع الخطأ (ممكن null إذا success)
  final dynamic data; // true أو "" حسب الحالة

  TrafficChargeResponse({
    required this.status,
    this.message,
    this.typeError,
    this.data,
  });

  factory TrafficChargeResponse.fromJson(Map<String, dynamic> json) {
    return TrafficChargeResponse(
      status: json["status"] ?? "",
      message: json["message"],
      typeError: json["type_error"]?.toString(),
      data: json["data"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "message": message,
      "type_error": typeError,
      "data": data,
    };
  }

  /// 🔧 دالة مساعدة لتسهيل الفحص
  bool get isSuccess => status == "success";
  bool get isError => status == "error";
}
