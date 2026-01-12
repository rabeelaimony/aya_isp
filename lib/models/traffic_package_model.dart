class TrafficPackage {
  final String id;
  final String name;
  final String quota;
  final String price;

  TrafficPackage({
    required this.id,
    required this.name,
    required this.quota,
    required this.price,
  });

  factory TrafficPackage.fromJson(Map<String, dynamic> json) {
    return TrafficPackage(
      id: json["PackageID"]?.toString() ?? "",
      name: json["PackageName"] ?? "",
      quota: json["quota"]?.toString() ?? "",
      price: json["Price"]?.toString() ?? "",
    );
  }
}
