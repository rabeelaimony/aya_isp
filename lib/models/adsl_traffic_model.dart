class AdslTrafficResponse {
  final String? status;
  final String? message;
  final AdslData? data;

  AdslTrafficResponse({this.status, this.message, this.data});

  factory AdslTrafficResponse.fromJson(Map<String, dynamic> json) {
    return AdslTrafficResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? AdslData.fromJson(json['data']) : null,
    );
  }
}

class AdslData {
  final double? totalTrafficPackage;
  final double? availableTraffic;
  final double? extraTraffic;
  final double? reducedSpeedTraffic;
  final double? monthTotalTrafficUsage;
  final double? percentageRest;
  final double? percentageUsage;
  final String? trafficRenewedAt;

  AdslData({
    this.totalTrafficPackage,
    this.availableTraffic,
    this.extraTraffic,
    this.reducedSpeedTraffic,
    this.monthTotalTrafficUsage,
    this.percentageRest,
    this.percentageUsage,
    this.trafficRenewedAt,
  });

  factory AdslData.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse('$v');
    }

    return AdslData(
      totalTrafficPackage: toDouble(json['total_traffic_package']),
      availableTraffic: toDouble(json['available_traffic']),
      extraTraffic: toDouble(json['extra_traffic']),
      reducedSpeedTraffic: toDouble(json['reduced_speed_traffic']),
      monthTotalTrafficUsage: toDouble(json['month_total_traffic_usage']),
      percentageRest: toDouble(json['percentage_rest']),
      percentageUsage: toDouble(json['percentage_usage']),
      trafficRenewedAt: json['traffic_renewed_at'],
    );
  }
}
