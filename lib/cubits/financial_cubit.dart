import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/financial_repository.dart';
import '../models/financial_item_model.dart';
import '../core/error_handler.dart';

abstract class FinancialState {}

class FinancialInitial extends FinancialState {}

class FinancialLoading extends FinancialState {}

class FinancialLoaded extends FinancialState {
  final List<FinancialItem> items;
  final int page;
  final bool hasMore;
  final int? total;
  final int? perPage;
  final int? lastPage;
  final bool isRefreshing;

  FinancialLoaded({
    required this.items,
    required this.page,
    required this.hasMore,
    this.total,
    this.perPage,
    this.lastPage,
    this.isRefreshing = false,
  });
}

class FinancialError extends FinancialState {
  final String message;
  FinancialError(this.message);
}

class FinancialCubit extends Cubit<FinancialState> {
  final FinancialRepository repository;
  FinancialCubit(this.repository) : super(FinancialInitial());

  Future<void> fetch({
    required String username,
    required String token,
    int perPage = 100,
    int page = 1,
  }) async {
    final currentState = state;
    if (currentState is FinancialLoaded) {
      emit(
        FinancialLoaded(
          items: currentState.items,
          page: currentState.page,
          hasMore: currentState.hasMore,
          total: currentState.total,
          perPage: currentState.perPage,
          lastPage: currentState.lastPage,
          isRefreshing: true,
        ),
      );
    } else {
      emit(FinancialLoading());
    }
    try {
      final data = await repository.getFinancialDetail(
        username: username,
        token: token,
        perPage: perPage,
        page: page,
      );
      final items = List<FinancialItem>.from(data.items);
      final pageFromServer = data.currentPage ?? page;
      final lastPage = data.lastPage;
      final hasMore = lastPage != null
          ? pageFromServer < lastPage
          : items.length == (data.perPage ?? perPage);

      // ترتيب من الأحدث إلى الأقدم (حسب تاريخ bd إن وُجد)
      items.sort((a, b) {
        DateTime? parse(String v) => DateTime.tryParse(v);
        final ad = parse(a.bd) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = parse(b.bd) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      return emit(
        FinancialLoaded(
          items: items,
          page: pageFromServer,
          hasMore: hasMore,
          total: data.total,
          perPage: data.perPage ?? perPage,
          lastPage: lastPage,
        ),
      );
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      emit(FinancialError(message));
    }
  }
}
