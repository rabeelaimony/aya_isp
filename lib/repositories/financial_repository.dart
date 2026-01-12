import '../services/financial_service.dart';
import '../models/financial_item_model.dart';

class FinancialResultModel {
  final List<FinancialItem> items;
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;

  FinancialResultModel({
    required this.items,
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
  });
}

class FinancialRepository {
  final FinancialService service;

  FinancialRepository(this.service);

  Future<FinancialResultModel> getFinancialDetail({
    required String username,
    required String token,
    int perPage = 100,
    int page = 1,
  }) async {
    final res = await service.getFinancialDetail(
      username: username,
      token: token,
      perPage: perPage,
      page: page,
    );

    final items = res.items
        .map(
          (e) => e is Map<String, dynamic>
              ? FinancialItem.fromJson(e)
              : FinancialItem.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    return FinancialResultModel(
      items: items,
      total: res.total,
      perPage: res.perPage,
      currentPage: res.currentPage,
      lastPage: res.lastPage,
    );
  }
}
