import 'package:bloc/bloc.dart';

import '../core/error_handler.dart';
import '../services/speed_service.dart';

class SpeedChangeState {
  final bool loading;
  final String? message;
  final int? newSpeed;
  final bool packagesLoading;
  final String? packagesError;
  final List<SpeedPackage> packages;

  SpeedChangeState({
    this.loading = false,
    this.message,
    this.newSpeed,
    this.packagesLoading = false,
    this.packagesError,
    this.packages = const [],
  });

  SpeedChangeState copyWith({
    bool? loading,
    String? message,
    bool resetMessage = false,
    int? newSpeed,
    bool? packagesLoading,
    String? packagesError,
    List<SpeedPackage>? packages,
    bool resetPackagesError = false,
  }) {
    return SpeedChangeState(
      loading: loading ?? this.loading,
      message: resetMessage ? null : (message ?? this.message),
      newSpeed: newSpeed ?? this.newSpeed,
      packagesLoading: packagesLoading ?? this.packagesLoading,
      packagesError: resetPackagesError
          ? null
          : (packagesError ?? this.packagesError),
      packages: packages ?? this.packages,
    );
  }
}

class SpeedChangeCubit extends Cubit<SpeedChangeState> {
  final SpeedService _service;

  SpeedChangeCubit({SpeedService? service})
    : _service = service ?? SpeedService(),
      super(SpeedChangeState());

  Future<void> loadPackages({
    required String accType,
    required String bearerToken,
    int? currentSpeed,
  }) async {
    emit(state.copyWith(packagesLoading: true, resetPackagesError: true));
    try {
      final packages = await _service.getSpeedPackages(
        accType: accType,
        bearerToken: bearerToken,
      );
      final filtered = packages.where((pkg) {
        if (pkg.speedVal == 0) return false;
        if (pkg.speedVal == 512) return false;
        if (currentSpeed != null && pkg.speedVal == currentSpeed) return false;
        return true;
      }).toList();
      emit(state.copyWith(packagesLoading: false, packages: filtered));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      emit(state.copyWith(packagesLoading: false, packagesError: message));
    }
  }

  Future<void> changeSpeed({
    required String username,
    required int speedId,
    required int speedVal,
    required String bearerToken,
  }) async {
    emit(state.copyWith(loading: true, resetMessage: true));
    try {
      final res = await _service.changeSpeed(
        username: username,
        speedId: speedId,
        speedVal: speedVal,
        bearerToken: bearerToken,
      );
      emit(
        state.copyWith(
          loading: false,
          message: res.message,
          newSpeed: res.newSpeed ?? speedVal,
        ),
      );
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      emit(state.copyWith(loading: false, message: message));
    }
  }
}
