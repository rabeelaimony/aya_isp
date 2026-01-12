import 'package:flutter_bloc/flutter_bloc.dart';

import 'traffic_package_state.dart';
import '../repositories/traffic_packages_repository.dart';
import '../core/error_handler.dart';

class TrafficPackagesCubit extends Cubit<TrafficPackagesState> {
  final TrafficPackagesRepository repository;

  TrafficPackagesCubit(this.repository) : super(TrafficPackagesInitial());

  Future<void> fetchPackages() async {
    emit(TrafficPackagesLoading());
    try {
      final packages = await repository.getPackages();
      emit(TrafficPackagesLoaded(packages));
    } catch (e) {
      final errorMessage = ErrorHandler.getErrorMessage(e);
      emit(TrafficPackagesError(errorMessage));
    }
  }
}
