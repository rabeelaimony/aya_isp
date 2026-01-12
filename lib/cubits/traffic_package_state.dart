import 'package:aya_isp/models/traffic_package_model.dart';

abstract class TrafficPackagesState {}

class TrafficPackagesInitial extends TrafficPackagesState {}

class TrafficPackagesLoading extends TrafficPackagesState {}

class TrafficPackagesLoaded extends TrafficPackagesState {
  final List<TrafficPackage> packages;
  TrafficPackagesLoaded(this.packages);
}

class TrafficPackagesError extends TrafficPackagesState {
  final String message;
  TrafficPackagesError(this.message);
}
