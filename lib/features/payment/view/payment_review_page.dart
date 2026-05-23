import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/payment/model/payment_review_response.dart';
import 'package:i_tabung/features/payment/view_model/payment_view_model.dart';
import 'package:i_tabung/features/tabung_dashboard/view/tabung_dashboard_page.dart';

enum PaymentReviewAction {
  saveInstead,
}

class PaymentReviewPage extends StatefulWidget {
  const PaymentReviewPage({
    super.key,
    required this.viewModel,
  });

  final PaymentViewModel viewModel;

  @override
  State<PaymentReviewPage> createState() => _PaymentReviewPageState();
}

class _PaymentReviewPageState extends State<PaymentReviewPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_handleStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locationContext = widget.viewModel.state.locationContext;
      if (locationContext == null || !locationContext.hasGrantedAccess) {
        final message = widget.viewModel.locationRequiredMessage(
          locationContext?.permissionStatus ?? 'unavailable',
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final state = widget.viewModel.state;
        final draft = state.draft;
        final review = state.review;

        if (draft == null || review == null) {
          return const Scaffold(
            body: Center(child: Text('Payment review is unavailable.')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F8FC),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0B5D56)),
            ),
            title: const Text(
              'Spending Habit Agent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18212E),
              ),
            ),
            centerTitle: true,
          ),
          body: MaxWidthContainer(
            child: SafeArea(
              child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 106,
                    height: 106,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF1EF),
                      border: Border.all(color: const Color(0xFFE56B5D), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      size: 44,
                      color: Color(0xFFC13C2C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Wait a moment!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF101A29),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _headlineText(draft.amount, review.spendingImpact),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF394657),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CategoryPill(review.guessedSpendingPlace.placeCategory),
                      const SizedBox(width: 8),
                      _ConfidencePill(review.guessedSpendingPlace.confidence),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TimelineCard(
                    tabungName: draft.tabung.name,
                    review: review,
                    spendingAmount: draft.amount,
                  ),
                  const SizedBox(height: 18),
                  _SuggestionCard(
                    suggestions: review.alternativeSuggestions,
                    recommendation: review.recommendation.message,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.isConfirming ? null : _saveInstead,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B7A63),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      icon: const Icon(Icons.savings_outlined, size: 20),
                      label: const Text(
                        'Save Instead',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: state.isConfirming ? null : _confirmPayment,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        foregroundColor: const Color(0xFF141E2D),
                        side: const BorderSide(color: Color(0xFFCCD6E3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: state.isConfirming
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Spend Anyway',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmPayment() async {
    try {
      await widget.viewModel.confirmPayment();
      if (!mounted) return;
      final tabungId = widget.viewModel.state.draft!.tabung.id;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Payment Confirmed'),
          content: const Text('Your spending has been recorded and the tabung balance is updated.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B5D56),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => TabungDashboardPage(tabungId: tabungId)),
        (route) => route.isFirst,
      );
    } catch (_) {
      // Error surface handled via listener.
    }
  }

  void _saveInstead() {
    Navigator.of(context).pop(PaymentReviewAction.saveInstead);
  }

  void _handleStateChanged() {
    final error = widget.viewModel.state.error;
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    widget.viewModel.clearError();
  }

  static String _headlineText(double amount, SpendingImpact impact) {
    if (impact.estimatedDelayValue > 0) {
      return 'Spending ${CurrencyUtils.asRm(amount)} now will delay\nyour goal by ${impact.estimatedDelayValue} ${impact.estimatedDelayUnit}!';
    }
    return impact.impactWarning;
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.tabungName,
    required this.review,
    required this.spendingAmount,
  });

  final String tabungName;
  final PaymentReviewResponse review;
  final double spendingAmount;

  @override
  Widget build(BuildContext context) {
    final progress = (review.tabungReminder.currentProgressPercentage / 100).clamp(0.0, 1.0);
    final delayedProgress = (progress * 0.8).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1FBFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE3F6F1),
                ),
                child: const Icon(Icons.flight_takeoff_rounded, size: 18, color: Color(0xFF0B7A63)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TARGET GOAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5D6A79),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tabungName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF172638),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Original Timeline',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2432),
                ),
              ),
              const Spacer(),
              Text(
                _originalTimelineLabel(review),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B7A63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFDDE8FA),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B7A63)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'If you spend ${CurrencyUtils.asRm(spendingAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC13C2C),
                  ),
                ),
              ),
              Text(
                _delayedTimelineLabel(review),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC13C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: delayedProgress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF6D7D2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCF3429)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 84,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFF4DAD6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _originalTimelineLabel(PaymentReviewResponse review) {
    final date = _tryParse(review.spendingImpact.newEstimatedEndDate);
    if (date == null) {
      return 'On Track';
    }
    final baseline = date.subtract(Duration(days: review.spendingImpact.estimatedDelayValue == 0 ? 0 : _delayDays(review)));
    return DateFormat('MMM y').format(baseline);
  }

  static String _delayedTimelineLabel(PaymentReviewResponse review) {
    final date = _tryParse(review.spendingImpact.newEstimatedEndDate);
    if (date == null) {
      return review.spendingImpact.estimatedDelayValue > 0
          ? '+${review.spendingImpact.estimatedDelayValue} ${review.spendingImpact.estimatedDelayUnit}'
          : 'No delay';
    }
    return DateFormat('MMM y').format(date);
  }

  static int _delayDays(PaymentReviewResponse review) {
    return switch (review.spendingImpact.estimatedDelayUnit) {
      'weeks' => review.spendingImpact.estimatedDelayValue * 7,
      'months' => review.spendingImpact.estimatedDelayValue * 30,
      _ => review.spendingImpact.estimatedDelayValue,
    };
  }

  static DateTime? _tryParse(String raw) {
    if (raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestions,
    required this.recommendation,
  });

  final List<AlternativeSuggestion> suggestions;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    final items = suggestions.isNotEmpty
        ? suggestions
        : const [
            AlternativeSuggestion(
              title: 'Save Instead',
              description: 'Keep this amount in your tabung for now.',
              estimatedSaving: 0,
            ),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF7FD3BF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF0A5B54), size: 20),
              const SizedBox(width: 8),
              const Text(
                'ALTERNATIVE SUGGESTION',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF114742),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            recommendation.trim().isNotEmpty ? recommendation : items.first.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF123232),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(items.length, (index) {
            final suggestion = items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
              child: _AlternativeSuggestionTile(
                index: index + 1,
                suggestion: suggestion,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AlternativeSuggestionTile extends StatelessWidget {
  const _AlternativeSuggestionTile({
    required this.index,
    required this.suggestion,
  });

  final int index;
  final AlternativeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B7A63),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title.trim().isEmpty ? 'Alternative $index' : suggestion.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14202E),
                  ),
                ),
                if (suggestion.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    suggestion.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF37505A),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Estimated saving: ${CurrencyUtils.asRm(suggestion.estimatedSaving)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B7A63),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF0B7A63)),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F7F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0B7A63),
        ),
      ),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  const _ConfidencePill(this.confidence);

  final String confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Confidence: ${confidence.toUpperCase()}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFFC13C2C),
        ),
      ),
    );
  }
}
