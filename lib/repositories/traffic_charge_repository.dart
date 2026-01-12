import '../services/traffic_charge_service.dart';

class TrafficChargeRepository {
  final TrafficChargeService service;

  TrafficChargeRepository(this.service);

  Future<Map<String, dynamic>> chargePackage({
    required String username,
    required String packageId,
    required String token,
  }) {
    return service.chargePackage(
      username: username,
      packageId: packageId,
      token: token,
    );
  }
}
