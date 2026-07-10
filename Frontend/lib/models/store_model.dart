class StoreModel {
  final String id;
  final String storeName;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? openingHours;

  const StoreModel({
    required this.id,
    required this.storeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.openingHours,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      storeName: json['store_name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      openingHours: json['opening_hours'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_name': storeName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'opening_hours': openingHours,
    };
  }
}
