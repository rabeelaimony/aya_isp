abstract class RechargeAdslState {}

class RechargeAdslInitial extends RechargeAdslState {}

class RechargeAdslLoading extends RechargeAdslState {}

class RechargeAdslSuccess extends RechargeAdslState {
  final String message;
  RechargeAdslSuccess(this.message);
}

class RechargeAdslError extends RechargeAdslState {
  final String message;
  RechargeAdslError(this.message);
}
