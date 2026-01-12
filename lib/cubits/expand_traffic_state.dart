abstract class ExpandTrafficState {}

class ExpandTrafficInitial extends ExpandTrafficState {}

class ExpandTrafficLoading extends ExpandTrafficState {}

class ExpandTrafficSuccess extends ExpandTrafficState {
  final String message;
  ExpandTrafficSuccess(this.message);
}

class ExpandTrafficError extends ExpandTrafficState {
  final String message;
  ExpandTrafficError(this.message);
}
