import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/userinfo_model.dart';
import '../services/userinfo_service.dart';
import '../core/error_handler.dart';
import '../core/user_mobile_cache.dart';

part 'userinfo_state.dart';

class UserInfoCubit extends Cubit<UserInfoState> {
  final UserInfoService _service;

  UserInfoCubit(this._service) : super(UserInfoInitial());

  Future<bool> fetchUserInfo(String token, String username) async {
    final currentState = state;
    if (currentState is UserInfoLoaded) {
      emit(UserInfoLoaded(currentState.userInfo, isRefreshing: true));
    } else {
      emit(UserInfoLoading());
    }

    try {
      final userInfo = await _service.getUserInfo(token, username);
      emit(UserInfoLoaded(userInfo));
      await UserMobileCache.save(
        username,
        userInfo.data?.user?.personal?.mobile,
      );
      return true;
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      emit(UserInfoError(message));
      return false;
    }
  }
}
