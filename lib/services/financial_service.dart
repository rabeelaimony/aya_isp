import 'package:dio/dio.dart';

import '../core/api_config.dart';

class FinancialResult {
  final List<dynamic> items;
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;

  FinancialResult({
    required this.items,
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
  });
}

class FinancialService {
  final Dio dio = ApiConfig.createDio(
    contentType: Headers.formUrlEncodedContentType,
  );

  Future<FinancialResult> getFinancialDetail({
    required String username,
    required String token,
    int perPage = 100,
    int page = 1,
  }) async {
    final formData = FormData.fromMap({
      'username': username,
      'per_page': perPage.toString(),
      'page': page.toString(),
    });

    final response = await dio.post(
      '/get_financial_detail',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: formData,
    );

    List<dynamic> list = const [];
    int? total;
    int? perPageResp;
    int? currentPage;
    int? lastPage;

    if (response.data is List) {
      list = response.data as List<dynamic>;
    } else if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      if (map['data'] is List) {
        list = map['data'] as List<dynamic>;
      }
      int? toInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        return int.tryParse(v.toString());
      }

      total = toInt(map['total']);
      perPageResp = toInt(map['per_page']);
      currentPage = toInt(map['current_page']);
      lastPage = toInt(map['last_page']);
    } else {
      throw Exception('Unexpected financial response: ${response.data}');
    }

    return FinancialResult(
      items: list,
      total: total,
      perPage: perPageResp,
      currentPage: currentPage,
      lastPage: lastPage,
    );
  }
}
