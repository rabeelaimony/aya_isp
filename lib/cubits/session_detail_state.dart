part of 'session_detail_cubit.dart';

abstract class SessionDetailState {}

class SessionDetailInitial extends SessionDetailState {}

class SessionDetailLoading extends SessionDetailState {}

class SessionDetailLoaded extends SessionDetailState {
  final SessionDetailResponse response;
  final int selectedYear;
  final int selectedMonth;
  final int page;
  final int perPage;
  final bool isRefreshing;

  SessionDetailLoaded(
    this.response, {
    required this.selectedYear,
    required this.selectedMonth,
    required this.page,
    required this.perPage,
    this.isRefreshing = false,
  });
}

class SessionDetailError extends SessionDetailState {
  final String message;
  SessionDetailError(this.message);
}
