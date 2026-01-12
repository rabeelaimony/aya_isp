part of 'adsl_traffic_cubit.dart';

abstract class AdslTrafficState {}

class AdslTrafficInitial extends AdslTrafficState {}

class AdslTrafficLoading extends AdslTrafficState {}

class AdslTrafficLoaded extends AdslTrafficState {
  final dynamic response;
  final bool isRefreshing;

  AdslTrafficLoaded(this.response, {this.isRefreshing = false});
}

class AdslTrafficError extends AdslTrafficState {
  final String message;
  AdslTrafficError(this.message);
}
