part of 'userinfo_cubit.dart';

abstract class UserInfoState {}

class UserInfoInitial extends UserInfoState {}

class UserInfoLoading extends UserInfoState {}

class UserInfoLoaded extends UserInfoState {
  final UserInfoResponse userInfo;
  final bool isRefreshing;

  UserInfoLoaded(
    this.userInfo, {
    this.isRefreshing = false,
  });
}

class UserInfoError extends UserInfoState {
  final String message;
  UserInfoError(this.message);
}
