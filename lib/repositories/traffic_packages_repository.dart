import '../models/traffic_package_model.dart';
import '../services/traffic_packages_service.dart';

class TrafficPackagesRepository {
  final TrafficPackagesService service;

  TrafficPackagesRepository(this.service);

  Future<List<TrafficPackage>> getPackages() async {
    final data = await service.fetchPackages();
    return data.map<TrafficPackage>((e) => TrafficPackage.fromJson(e)).toList();
  }
}
