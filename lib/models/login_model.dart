class LoginResponse {
  final String status;
  final String? message;
  final LoginData? data;

  LoginResponse({required this.status, this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? '',
      message: json['message'],
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final int userId;
  final String name;
  final String token;

  LoginData({required this.userId, required this.name, required this.token});

  factory LoginData.fromJson(Map<String, dynamic> json) {
    final rawId = json['user_id'];
    int parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is double) {
      parsedId = rawId.toInt();
    } else {
      parsedId = int.tryParse(rawId?.toString() ?? '') ?? 0;
    }

    return LoginData(
      userId: parsedId,
      name: json['name'] ?? '',
      token: json['token'] ?? '',
    );
  }
}
