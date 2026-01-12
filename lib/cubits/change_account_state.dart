abstract class ChangeAccountState {}

class ChangeAccountInitial extends ChangeAccountState {}

class ChangeAccountLoading extends ChangeAccountState {}

class ChangeAccountSuccess extends ChangeAccountState {
  final String message;
  ChangeAccountSuccess(this.message);
}

class ChangeAccountError extends ChangeAccountState {
  final String message;
  ChangeAccountError(this.message);
}
