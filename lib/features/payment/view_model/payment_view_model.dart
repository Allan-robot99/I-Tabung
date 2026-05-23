import 'package:flutter/foundation.dart';
import 'package:i_tabung/features/payment/model/payment_review_request.dart';
import 'package:i_tabung/features/payment/model/payment_review_response.dart';
import 'package:i_tabung/features/payment/model/payment_transaction_draft.dart';
import 'package:i_tabung/features/payment/repository/payment_repository.dart';
import 'package:i_tabung/features/payment/service/location_service.dart';

class PaymentViewState {
  const PaymentViewState({
    this.draft,
    this.review,
    this.locationContext,
    this.isLoading = false,
    this.isConfirming = false,
    this.error,
  });

  final PaymentTransactionDraft? draft;
  final PaymentReviewResponse? review;
  final PaymentLocationContext? locationContext;
  final bool isLoading;
  final bool isConfirming;
  final String? error;

  PaymentViewState copyWith({
    PaymentTransactionDraft? draft,
    PaymentReviewResponse? review,
    PaymentLocationContext? locationContext,
    bool? isLoading,
    bool? isConfirming,
    String? error,
    bool clearReview = false,
    bool clearError = false,
  }) {
    return PaymentViewState(
      draft: draft ?? this.draft,
      review: clearReview ? null : (review ?? this.review),
      locationContext: locationContext ?? this.locationContext,
      isLoading: isLoading ?? this.isLoading,
      isConfirming: isConfirming ?? this.isConfirming,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel(this._repository, this._locationService);

  final PaymentRepository _repository;
  final LocationService _locationService;

  PaymentViewState _state = const PaymentViewState();
  PaymentViewState get state => _state;

  Future<PaymentLocationContext> refreshLocationStatus({
    bool requestPermission = false,
  }) async {
    final locationContext = await _locationService.getCurrentLocationContext(
      requestPermission: requestPermission,
    );
    _state = _state.copyWith(
      locationContext: locationContext,
      clearError: true,
    );
    notifyListeners();
    return locationContext;
  }

  Future<bool> openAppSettings() => _locationService.openAppSettings();

  Future<bool> openLocationSettings() => _locationService.openLocationSettings();

  void setDraft(PaymentTransactionDraft draft) {
    _state = _state.copyWith(draft: draft, clearReview: true, clearError: true);
    notifyListeners();
  }

  Future<bool> generateReview() async {
    final draft = _state.draft;
    if (draft == null) {
      _setError('Missing payment details.');
      return false;
    }

    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final locationContext = await _locationService.getCurrentLocationContext();
      if (!locationContext.hasGrantedAccess) {
        throw Exception(locationRequiredMessage(locationContext.permissionStatus));
      }
      final review = await _repository.requestReview(
        draft: draft,
        locationContext: locationContext,
      );
      _state = _state.copyWith(
        locationContext: locationContext,
        review: review,
        isLoading: false,
        clearError: true,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''), isLoading: false);
      return false;
    }
  }

  Future<void> confirmPayment() async {
    final draft = _state.draft;
    final review = _state.review;
    final locationContext = _state.locationContext;

    if (draft == null || review == null || locationContext == null) {
      throw Exception('Payment review is incomplete.');
    }
    if (!locationContext.hasGrantedAccess) {
      throw Exception(locationRequiredMessage(locationContext.permissionStatus));
    }

    _state = _state.copyWith(isConfirming: true, clearError: true);
    notifyListeners();

    try {
      await _repository.confirmPayment(
        draft: draft,
        review: review,
        locationContext: locationContext,
      );
      _state = _state.copyWith(isConfirming: false, clearError: true);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''), isConfirming: false);
      rethrow;
    }
  }

  void clearError() {
    if (_state.error == null) return;
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  void _setError(String message, {bool? isLoading, bool? isConfirming}) {
    _state = _state.copyWith(
      error: message,
      isLoading: isLoading ?? _state.isLoading,
      isConfirming: isConfirming ?? _state.isConfirming,
    );
    notifyListeners();
  }

  String locationRequiredMessage(String permissionStatus) {
    switch (permissionStatus) {
      case 'service_disabled':
        return 'Turn on device location services before continuing.';
      case 'denied_forever':
        return 'Location access is required. Please allow it from app settings.';
      case 'denied':
        return 'Location access is required before you can continue.';
      default:
        return 'We could not read your current location. Please try again.';
    }
  }
}
