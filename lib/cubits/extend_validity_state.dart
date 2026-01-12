abstract class ExtendValidityState {}

class ExtendValidityInitial extends ExtendValidityState {}

class ExtendValidityLoading extends ExtendValidityState {}

class ExtendValiditySuccess extends ExtendValidityState {
  final String message;

  ExtendValiditySuccess(this.message);
}

class ExtendValidityError extends ExtendValidityState {
  final String message;

  ExtendValidityError(this.message);
}
