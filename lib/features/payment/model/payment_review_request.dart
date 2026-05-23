class PaymentLocationContext {
  const PaymentLocationContext({
    required this.permissionStatus,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
  });

  final String permissionStatus;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;

  bool get hasGrantedAccess =>
      latitude != null &&
      longitude != null &&
      (permissionStatus == 'always' || permissionStatus == 'whileInUse');

  Map<String, dynamic> toJson() => {
        'locationPermissionStatus': permissionStatus,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracyMeters != null) 'locationAccuracy': accuracyMeters,
      };
}

class PaymentReviewRequest {
  const PaymentReviewRequest({
    required this.userId,
    required this.familyId,
    required this.tabungId,
    required this.paymentAmount,
    required this.buyingPurpose,
    required this.locationContext,
  });

  final String userId;
  final String familyId;
  final String tabungId;
  final double paymentAmount;
  final String buyingPurpose;
  final PaymentLocationContext locationContext;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'familyId': familyId,
        'tabungId': tabungId,
        'paymentAmount': paymentAmount,
        'buyingPurpose': buyingPurpose,
        'locationContext': locationContext.toJson(),
      };
}
