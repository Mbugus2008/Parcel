class PricingRate {
  String? key;
  String? locationFrom;
  String? locationTo;
  double? weightFrom;
  double? weightTo;
  double? subsequent;

  PricingRate({
    this.key,
    this.locationFrom,
    this.locationTo,
    this.weightFrom,
    this.weightTo,
    this.subsequent,
  });

  factory PricingRate.fromJson(Map<String, dynamic> json) {
    return PricingRate(
      key: json['Key'] as String?,
      locationFrom: json['Location_From'] as String?,
      locationTo: json['Location_To'] as String?,
      weightFrom: (json['Weight_From'] as num?)?.toDouble(),
      weightTo: (json['Weight_To'] as num?)?.toDouble(),
      subsequent: (json['Subsequent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Key': key,
      'Location_From': locationFrom,
      'Location_To': locationTo,
      'Weight_From': weightFrom,
      'Weight_To': weightTo,
      'Subsequent': subsequent,
    };
  }
}
