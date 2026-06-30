class AddressModel {
  const AddressModel({
    required this.id,
    required this.userId,
    required this.receiverName,
    required this.receiverPhone,
    this.province,
    this.district,
    this.ward,
    required this.streetAddress,
    this.isDefault = false,
  });

  final String id;
  final String userId;
  final String receiverName;
  final String receiverPhone;
  final String? province;
  final String? district;
  final String? ward;
  final String streetAddress;
  final bool isDefault;

  String get fullAddressText {
    final parts = [
      streetAddress,
      if (ward != null && ward!.isNotEmpty) ward,
      if (district != null && district!.isNotEmpty) district,
      if (province != null && province!.isNotEmpty) province,
    ];
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      receiverName: json['receiver_name'] as String,
      receiverPhone: json['receiver_phone'] as String,
      province: json['province'] as String?,
      district: json['district'] as String?,
      ward: json['ward'] as String?,
      streetAddress: json['street_address'] as String,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'province': province,
      'district': district,
      'ward': ward,
      'streetAddress': streetAddress,
      'isDefault': isDefault,
    };
  }
}
