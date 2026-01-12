import '../services/expand_traffic_service.dart';

class ExpandTrafficRepository {
  final ExpandTrafficService service;

  ExpandTrafficRepository(this.service);

  Future<Map<String, dynamic>> extend({
    required String username,
    required int reqSize,
    required String token,
  }) {
    return service.expandTrafficSelection(
      username: username,
      reqSize: reqSize,
      token: token,
    );
  }
}
