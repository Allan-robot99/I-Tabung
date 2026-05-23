class PaymentReviewResponse {
  const PaymentReviewResponse({
    required this.guessedSpendingPlace,
    required this.tabungReminder,
    required this.recurringTargetReminder,
    required this.spendingImpact,
    required this.alternativeSuggestions,
    required this.recommendation,
    required this.summary,
    this.promptVersion,
  });

  final GuessedSpendingPlace guessedSpendingPlace;
  final TabungReminder tabungReminder;
  final RecurringTargetReminder recurringTargetReminder;
  final SpendingImpact spendingImpact;
  final List<AlternativeSuggestion> alternativeSuggestions;
  final Recommendation recommendation;
  final String summary;
  final String? promptVersion;

  factory PaymentReviewResponse.fromJson(Map<String, dynamic> json) {
    return PaymentReviewResponse(
      guessedSpendingPlace: GuessedSpendingPlace.fromJson(
        Map<String, dynamic>.from(json['guessedSpendingPlace'] as Map? ?? const {}),
      ),
      tabungReminder: TabungReminder.fromJson(
        Map<String, dynamic>.from(json['tabungReminder'] as Map? ?? const {}),
      ),
      recurringTargetReminder: RecurringTargetReminder.fromJson(
        Map<String, dynamic>.from(json['recurringTargetReminder'] as Map? ?? const {}),
      ),
      spendingImpact: SpendingImpact.fromJson(
        Map<String, dynamic>.from(json['spendingImpact'] as Map? ?? const {}),
      ),
      alternativeSuggestions: (json['alternativeSuggestions'] as List? ?? const [])
          .map((item) => AlternativeSuggestion.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      recommendation: Recommendation.fromJson(
        Map<String, dynamic>.from(json['recommendation'] as Map? ?? const {}),
      ),
      summary: json['summary']?.toString() ?? '',
      promptVersion: json['promptVersion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'guessedSpendingPlace': guessedSpendingPlace.toJson(),
        'tabungReminder': tabungReminder.toJson(),
        'recurringTargetReminder': recurringTargetReminder.toJson(),
        'spendingImpact': spendingImpact.toJson(),
        'alternativeSuggestions': alternativeSuggestions.map((item) => item.toJson()).toList(growable: false),
        'recommendation': recommendation.toJson(),
        'summary': summary,
        if (promptVersion != null) 'promptVersion': promptVersion,
      };
}

class GuessedSpendingPlace {
  const GuessedSpendingPlace({
    required this.placeName,
    required this.placeCategory,
    required this.confidence,
    required this.reason,
  });

  final String placeName;
  final String placeCategory;
  final String confidence;
  final String reason;

  factory GuessedSpendingPlace.fromJson(Map<String, dynamic> json) => GuessedSpendingPlace(
        placeName: json['placeName']?.toString() ?? 'Unknown',
        placeCategory: json['placeCategory']?.toString() ?? 'general purchase',
        confidence: json['confidence']?.toString() ?? 'low',
        reason: json['reason']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'placeName': placeName,
        'placeCategory': placeCategory,
        'confidence': confidence,
        'reason': reason,
      };
}

class TabungReminder {
  const TabungReminder({
    required this.message,
    required this.currentProgressPercentage,
  });

  final String message;
  final double currentProgressPercentage;

  factory TabungReminder.fromJson(Map<String, dynamic> json) => TabungReminder(
        message: json['message']?.toString() ?? '',
        currentProgressPercentage: (json['currentProgressPercentage'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'currentProgressPercentage': currentProgressPercentage,
      };
}

class RecurringTargetReminder {
  const RecurringTargetReminder({
    required this.message,
    required this.recurringAmount,
    required this.currentPeriodSaved,
    required this.remainingForThisPeriod,
  });

  final String message;
  final double recurringAmount;
  final double currentPeriodSaved;
  final double remainingForThisPeriod;

  factory RecurringTargetReminder.fromJson(Map<String, dynamic> json) => RecurringTargetReminder(
        message: json['message']?.toString() ?? '',
        recurringAmount: (json['recurringAmount'] as num?)?.toDouble() ?? 0,
        currentPeriodSaved: (json['currentPeriodSaved'] as num?)?.toDouble() ?? 0,
        remainingForThisPeriod: (json['remainingForThisPeriod'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'recurringAmount': recurringAmount,
        'currentPeriodSaved': currentPeriodSaved,
        'remainingForThisPeriod': remainingForThisPeriod,
      };
}

class SpendingImpact {
  const SpendingImpact({
    required this.impactWarning,
    required this.estimatedDelayValue,
    required this.estimatedDelayUnit,
    required this.newEstimatedEndDate,
  });

  final String impactWarning;
  final int estimatedDelayValue;
  final String estimatedDelayUnit;
  final String newEstimatedEndDate;

  factory SpendingImpact.fromJson(Map<String, dynamic> json) => SpendingImpact(
        impactWarning: json['impactWarning']?.toString() ?? '',
        estimatedDelayValue: (json['estimatedDelayValue'] as num?)?.toInt() ?? 0,
        estimatedDelayUnit: json['estimatedDelayUnit']?.toString() ?? 'days',
        newEstimatedEndDate: json['newEstimatedEndDate']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'impactWarning': impactWarning,
        'estimatedDelayValue': estimatedDelayValue,
        'estimatedDelayUnit': estimatedDelayUnit,
        'newEstimatedEndDate': newEstimatedEndDate,
      };
}

class AlternativeSuggestion {
  const AlternativeSuggestion({
    required this.title,
    required this.description,
    required this.estimatedSaving,
  });

  final String title;
  final String description;
  final double estimatedSaving;

  factory AlternativeSuggestion.fromJson(Map<String, dynamic> json) => AlternativeSuggestion(
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        estimatedSaving: (json['estimatedSaving'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'estimatedSaving': estimatedSaving,
      };
}

class Recommendation {
  const Recommendation({
    required this.shouldProceed,
    required this.message,
  });

  final bool shouldProceed;
  final String message;

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        shouldProceed: json['shouldProceed'] as bool? ?? false,
        message: json['message']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'shouldProceed': shouldProceed,
        'message': message,
      };
}
