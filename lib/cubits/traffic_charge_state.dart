abstract class TrafficChargeState {}

class TrafficChargeInitial extends TrafficChargeState {}

class TrafficChargeLoading extends TrafficChargeState {}

class TrafficChargeSuccess extends TrafficChargeState {
  final String message;
  TrafficChargeSuccess(this.message);
}

class TrafficChargeError extends TrafficChargeState {
  final String message;
  TrafficChargeError(this.message);
}
