import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/core/utils/app_bottom_nav_bar.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/dashboard/model/dashboard_models.dart';
import 'package:i_tabung/features/payment/view/payment_form_page.dart';
import 'package:i_tabung/features/tabung_dashboard/view/tabung_dashboard_page.dart';
import 'package:i_tabung/features/transactions/model/transaction_flow_type.dart';
import 'package:i_tabung/features/transactions/repository/transaction_repository.dart';

class TabungActionPickerPage extends StatefulWidget {
  const TabungActionPickerPage({
    super.key,
    required this.flowType,
    required this.tabungs,
  });

  final TransactionFlowType flowType;
  final List<DashboardTabungSummary> tabungs;

  @override
  State<TabungActionPickerPage> createState() => _TabungActionPickerPageState();
}

class _TabungActionPickerPageState extends State<TabungActionPickerPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpend = widget.flowType == TransactionFlowType.spend;
    final currentTabung = widget.tabungs[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5F3),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: isSpend ? 3 : 1,
        onTap: _handleBottomNavTap,
      ),
      body: MaxWidthContainer(
        child: SafeArea(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF162433)),
                  ),
                  Expanded(
                    child: Text(
                      isSpend ? 'Spend from Tabung' : 'Deposit to Tabung',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A6B4A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      isSpend ? 'Choose Your Tabung' : 'Pick a Tabung for Deposit',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSpend
                          ? 'Swipe to choose where this spending should be recorded.'
                          : 'Swipe to choose which savings goal will receive this deposit.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E8E),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 460,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.tabungs.length,
                        onPageChanged: (index) => setState(() => _currentIndex = index),
                        itemBuilder: (context, index) => _TabungActionCard(
                          tabung: widget.tabungs[index],
                          flowType: widget.flowType,
                          onTap: () => _openEntry(widget.tabungs[index]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PickerPageIndicator(
                      count: widget.tabungs.length,
                      currentIndex: _currentIndex,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _openEntry(currentTabung),
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
                                isSpend ? 'Continue to Spend' : 'Continue to Deposit',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _openEntry(DashboardTabungSummary tabung) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => widget.flowType == TransactionFlowType.spend
            ? PaymentFormPage(tabung: tabung)
            : TransactionEntryPage(
                flowType: widget.flowType,
                tabung: tabung,
              ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        if (widget.flowType != TransactionFlowType.deposit) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TabungActionPickerPage(
                flowType: TransactionFlowType.deposit,
                tabungs: widget.tabungs,
              ),
            ),
          );
        }
        break;
      case 3:
        if (widget.flowType != TransactionFlowType.spend) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TabungActionPickerPage(
                flowType: TransactionFlowType.spend,
                tabungs: widget.tabungs,
              ),
            ),
          );
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This navigation action is not available from this screen yet.'),
          ),
        );
        break;
    }
  }
}

class _TabungActionCard extends StatelessWidget {
  const _TabungActionCard({
    required this.tabung,
    required this.flowType,
    required this.onTap,
  });

  final DashboardTabungSummary tabung;
  final TransactionFlowType flowType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = _TabungListTheme.fromType(tabung.type);
    final progress = tabung.goalAmount <= 0 ? 0.0 : (tabung.currentAmount / tabung.goalAmount).clamp(0.0, 1.0);
    final actionLabel = flowType == TransactionFlowType.spend ? 'Record Spending' : 'Add Deposit';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        elevation: 3,
        shadowColor: const Color(0xFF1A6B4A).withValues(alpha: 0.10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(34),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: theme.heroColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _prettyType(tabung.type),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Image.asset(theme.assetPath, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  tabung.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF172638),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${CurrencyUtils.asRm(tabung.currentAmount)} saved of ${CurrencyUtils.asRm(tabung.goalAmount)} target',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF647384),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFE0E8F4),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7F3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tabung.status,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A6B4A),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: theme.accentColor, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerPageIndicator extends StatelessWidget {
  const _PickerPageIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A6B4A) : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

String _prettyType(String type) {
  if (type.trim().isEmpty) return 'Tabung';
  return type
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

class TransactionEntryPage extends ConsumerStatefulWidget {
  const TransactionEntryPage({
    super.key,
    required this.flowType,
    required this.tabung,
  });

  final TransactionFlowType flowType;
  final DashboardTabungSummary tabung;

  @override
  ConsumerState<TransactionEntryPage> createState() => _TransactionEntryPageState();
}

class _TransactionEntryPageState extends ConsumerState<TransactionEntryPage> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isSubmitting = false;
  String _paymentMethod = 'Bank Transfer';

  bool get _isSpend => widget.flowType == TransactionFlowType.spend;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF162433)),
        ),
        title: Text(
          _isSpend ? 'SPENDING HABIT COACH' : 'DEPOSIT TRACKER',
          style: const TextStyle(
            fontSize: 14,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0B5D56),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSpend ? 'New Spending' : 'New Deposit',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111D2C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isSpend
                    ? 'Log your latest purchase to stay on track.'
                    : 'Record a new deposit for this tabung.',
                style: const TextStyle(
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
              if (_isSpend) ...[
                const SizedBox(height: 24),
                const _FieldLabel('Purpose'),
                const SizedBox(height: 10),
                _TextEntryField(
                  controller: _purposeController,
                  hintText: 'e.g., Buying a toy',
                  icon: Icons.shopping_bag_outlined,
                ),
                const SizedBox(height: 24),
                const _FieldLabel('Payment Method'),
                const SizedBox(height: 10),
                _PaymentMethodCard(
                  method: _paymentMethod,
                  onTap: _pickPaymentMethod,
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
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
                        _isSubmitting ? 'Saving...' : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
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
  }

  Future<void> _pickPaymentMethod() async {
    final methods = ['Bank Transfer', 'Cash', 'E-Wallet'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: methods
                .map(
                  (method) => ListTile(
                    title: Text(method),
                    trailing: method == _paymentMethod
                        ? const Icon(Icons.check_rounded, color: Color(0xFF0B5D56))
                        : null,
                    onTap: () => Navigator.of(context).pop(method),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _paymentMethod = selected);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount.');
      return;
    }
    if (_isSpend && _purposeController.text.trim().isEmpty) {
      _showSnackBar('Please enter a purpose for this spending.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(transactionRepositoryProvider).submitTransaction(
            flowType: widget.flowType,
            tabungId: widget.tabung.id,
            tabungName: widget.tabung.name,
            amount: amount,
            purpose: _purposeController.text.trim(),
            paymentMethod: _paymentMethod,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(_isSpend ? 'Spending Saved' : 'Deposit Saved'),
            content: Text(
              _isSpend
                  ? 'Your spending has been recorded and the tabung balance is updated.'
                  : 'Your deposit has been recorded and the tabung balance is updated.',
            ),
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
          );
        },
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TabungDashboardPage(tabungId: widget.tabung.id),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
        prefixText: '\$ ',
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

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.onTap,
  });

  final String method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD7E3F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_rounded, color: Color(0xFF26394A)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172638),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Default account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A8898),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.unfold_more_rounded, color: Color(0xFF172638)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabungListTheme {
  const _TabungListTheme({
    required this.assetPath,
    required this.heroColor,
    required this.accentColor,
  });

  final String assetPath;
  final Color heroColor;
  final Color accentColor;

  factory _TabungListTheme.fromType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('travel')) {
      return const _TabungListTheme(
        assetPath: 'assets/images/tabung/travel_jar.png',
        heroColor: Color(0xFFE0F5F2),
        accentColor: Color(0xFF0A746D),
      );
    }
    if (normalized.contains('electronic') || normalized.contains('gadget')) {
      return const _TabungListTheme(
        assetPath: 'assets/images/tabung/electronicdevice_jar.png',
        heroColor: Color(0xFFE3F4F1),
        accentColor: Color(0xFF0A746D),
      );
    }
    if (normalized.contains('food')) {
      return const _TabungListTheme(
        assetPath: 'assets/images/tabung/food_jar.png',
        heroColor: Color(0xFFF8EFD7),
        accentColor: Color(0xFFC38B2C),
      );
    }
    if (normalized.contains('growth') || normalized.contains('education')) {
      return const _TabungListTheme(
        assetPath: 'assets/images/tabung/personal_growth_jar.png',
        heroColor: Color(0xFFE7F5E7),
        accentColor: Color(0xFF4C8F66),
      );
    }
    if (normalized.contains('sport') || normalized.contains('art')) {
      return const _TabungListTheme(
        assetPath: 'assets/images/tabung/sport_art_jar.png',
        heroColor: Color(0xFFF6EFE6),
        accentColor: Color(0xFFB07D3C),
      );
    }
    return const _TabungListTheme(
      assetPath: 'assets/images/tabung/travel_jar.png',
      heroColor: Color(0xFFE0F5F2),
      accentColor: Color(0xFF0A746D),
    );
  }
}
