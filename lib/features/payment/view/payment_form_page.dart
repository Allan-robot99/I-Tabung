import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/dashboard/model/dashboard_models.dart';
import 'package:i_tabung/features/payment/model/payment_review_request.dart';
import 'package:i_tabung/features/payment/model/payment_transaction_draft.dart';
import 'package:i_tabung/features/payment/repository/payment_repository.dart';
import 'package:i_tabung/features/payment/service/location_service.dart';
import 'package:i_tabung/features/payment/view/payment_review_page.dart';
import 'package:i_tabung/features/payment/view_model/payment_view_model.dart';

class PaymentFormPage extends ConsumerStatefulWidget {
  const PaymentFormPage({
    super.key,
    required this.tabung,
  });

  final DashboardTabungSummary tabung;

  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  late final PaymentViewModel _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel.state.locationContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _viewModel.refreshLocationStatus();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentViewModel(
      ref.read(paymentRepositoryProvider),
      ref.read(locationServiceProvider),
    );
    _viewModel.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleStateChanged);
    _viewModel.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F8FC),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF162433)),
            ),
            title: const Text(
              'SPENDING HABIT COACH',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B5D56),
              ),
            ),
            centerTitle: true,
          ),
          body: MaxWidthContainer(
            child: SafeArea(
              child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 24),
              children: [
                const Text(
                  'New Spending',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111D2C),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Log your latest purchase to stay on track.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4E5C6C),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.savings_outlined, color: Color(0xFF0B5D56), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.tabung.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF162433),
                          ),
                        ),
                      ),
                      Text(
                        CurrencyUtils.asRm(widget.tabung.currentAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF627285),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _FieldLabel('Amount'),
                const SizedBox(height: 10),
                _AmountField(controller: _amountController),
              const SizedBox(height: 24),
                _LocationRequirementCard(
                  locationContext: state.locationContext,
                  isLoading: state.isLoading,
                  onAllowLocation: _ensureLocationAccess,
                ),
                const SizedBox(height: 24),
                const _FieldLabel('Purpose'),
                const SizedBox(height: 10),
                _TextEntryField(
                  controller: _purposeController,
                  hintText: 'e.g., Buying a toy',
                  icon: Icons.shopping_bag_outlined,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF78D2C2),
                      foregroundColor: const Color(0xFF102334),
                      minimumSize: const Size.fromHeight(58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.isLoading ? 'Reviewing...' : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (state.isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.arrow_forward_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount.');
      return;
    }

    final purpose = _purposeController.text.trim();
    if (purpose.isEmpty) {
      _showSnackBar('Please enter a purpose for this spending.');
      return;
    }

    _viewModel.setDraft(
      PaymentTransactionDraft(
        tabung: widget.tabung,
        amount: amount,
        buyingPurpose: purpose,
      ),
    );

    final hasLocation = await _ensureLocationAccess(requestPermission: true);
    if (!mounted || !hasLocation) return;

    final success = await _viewModel.generateReview();
    if (!mounted || !success) return;

    final result = await Navigator.of(context).push<PaymentReviewAction>(
      MaterialPageRoute(
        builder: (_) => PaymentReviewPage(viewModel: _viewModel),
      ),
    );
    if (!mounted || result != PaymentReviewAction.saveInstead) return;

    _showSnackBar('Nice choice. Your spending was not recorded and your tabung stays on track.');
  }

  void _handleStateChanged() {
    final error = _viewModel.state.error;
    if (error == null || !mounted) return;
    _showSnackBar(error);
    _viewModel.clearError();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _ensureLocationAccess({bool requestPermission = true}) async {
    final locationContext = await _viewModel.refreshLocationStatus(
      requestPermission: requestPermission,
    );
    if (locationContext.hasGrantedAccess) {
      return true;
    }

    if (!mounted) return false;
    await _showLocationAccessDialog(locationContext.permissionStatus);
    return false;
  }

  Future<void> _showLocationAccessDialog(String permissionStatus) async {
    final title = switch (permissionStatus) {
      'service_disabled' => 'Turn On Location Services',
      'denied_forever' => 'Allow Location Access',
      'denied' => 'Location Permission Required',
      _ => 'Location Needed',
    };
    final message = switch (permissionStatus) {
      'service_disabled' =>
        'I-Tabung needs your current location before the spending coach can review this payment. Please turn on device location services first.',
      'denied_forever' =>
        'I-Tabung needs location access before you can continue. Please open app settings and allow location permission.',
      'denied' =>
        'I-Tabung needs location access before you can continue to the coach reminder screen.',
      _ =>
        'We could not read your current location. Please try again after allowing location access.',
    };
    final actionLabel = switch (permissionStatus) {
      'service_disabled' => 'Open Location Settings',
      'denied_forever' => 'Open App Settings',
      _ => 'Try Again',
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              switch (permissionStatus) {
                case 'service_disabled':
                  await _viewModel.openLocationSettings();
                  break;
                case 'denied_forever':
                  await _viewModel.openAppSettings();
                  break;
                default:
                  await _ensureLocationAccess(requestPermission: true);
                  break;
              }
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _LocationRequirementCard extends StatelessWidget {
  const _LocationRequirementCard({
    required this.locationContext,
    required this.isLoading,
    required this.onAllowLocation,
  });

  final PaymentLocationContext? locationContext;
  final bool isLoading;
  final Future<bool> Function({bool requestPermission}) onAllowLocation;

  @override
  Widget build(BuildContext context) {
    final hasAccess = locationContext?.hasGrantedAccess ?? false;
    final statusText = switch (locationContext?.permissionStatus) {
      'always' || 'whileInUse' => 'Current location ready for coach review',
      'service_disabled' => 'Turn on device location services to continue',
      'denied_forever' => 'Location is blocked. Open settings to continue',
      'denied' => 'Location permission is required before continuing',
      'unavailable' => 'We could not read your location yet',
      _ => 'Allow location access so the coach can review this payment',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAccess ? const Color(0xFFEFFCF7) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasAccess ? const Color(0xFF8AD4B0) : const Color(0xFFD7E3F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasAccess ? Icons.my_location_rounded : Icons.location_on_outlined,
            color: hasAccess ? const Color(0xFF0B8F63) : const Color(0xFF5A6980),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAccess ? 'Location Access Confirmed' : 'Location Required',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF162433),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF5A6980),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          onAllowLocation(requestPermission: true);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B5D56),
                    side: const BorderSide(color: Color(0xFF9EDDD1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(hasAccess ? 'Refresh Location' : 'Allow Location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF172638),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: '0.00',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 18, right: 8),
          child: Icon(Icons.payments_outlined, color: Color(0xFF0B5D56), size: 24),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 56),
        prefixText: 'RM ',
        prefixStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF162433),
        ),
        hintStyle: const TextStyle(
          fontSize: 18,
          color: Color(0xFF9AA7B7),
        ),
        filled: true,
        fillColor: const Color(0xFFF2F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFFD7E3F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFFD7E3F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFF78D2C2), width: 1.4),
        ),
      ),
    );
  }
}

class _TextEntryField extends StatelessWidget {
  const _TextEntryField({
    required this.controller,
    required this.hintText,
    required this.icon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF7A8898)),
        hintStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF9AA7B7),
        ),
        filled: true,
        fillColor: const Color(0xFFF2F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFD7E3F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFD7E3F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF78D2C2), width: 1.4),
        ),
      ),
    );
  }
}
