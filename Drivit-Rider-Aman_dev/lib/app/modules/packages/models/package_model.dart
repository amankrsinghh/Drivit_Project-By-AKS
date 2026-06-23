enum PackageType { hourly, outstation }

class Package {
  final String id;
  final String name;
  final String type; // 'Hourly' or 'Outstation'
  final String duration;
  final double basePrice;
  final double overtimeCharge;
  final double nightCharge;
  final double locationChangeCharge;
  final String status;

  Package({
    required this.id,
    required this.name,
    required this.type,
    required this.duration,
    required this.basePrice,
    required this.overtimeCharge,
    required this.nightCharge,
    required this.locationChangeCharge,
    required this.status,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Hourly',
      duration: json['duration'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      overtimeCharge: (json['overtimeCharge'] ?? 0).toDouble(),
      nightCharge: (json['nightCharge'] ?? 0).toDouble(),
      locationChangeCharge: (json['locationChangeCharge'] ?? 0).toDouble(),
      status: json['status'] ?? 'Active',
    );
  }
}

class PackageDetailRow {
  final String left;
  final String right;
  const PackageDetailRow(this.left, this.right);
}