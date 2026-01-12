import '../models/extend_validity_response.dart';
import '../services/extend_validity_service.dart';

class ExtendValidityRepository {
  final ExtendValidityService _service;

  ExtendValidityRepository(this._service);

  Future<ExtendValidityResponse> extend({
    required String username,
    required String token,
  }) {
    return _service.extendExpiry(username: username, token: token);
  }
}
