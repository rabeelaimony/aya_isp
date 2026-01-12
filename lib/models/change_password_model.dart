class ChangePasswordResponse {
  final dynamic msg; // ممكن تكون String أو List<String>
  final bool status; // true أو false
  final dynamic data; // غالباً {} أو []

  ChangePasswordResponse({required this.msg, required this.status, this.data});

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      msg: json["msg"],
      status: json["status"] ?? false,
      data: json["data"],
    );
  }

  /// 🔧 دالة مساعدة: ترجع الرسالة كنص واحد
  String get message {
    if (msg is String) {
      return msg;
    } else if (msg is List) {
      return msg.join(" , ");
    }
    return "";
  }
}
