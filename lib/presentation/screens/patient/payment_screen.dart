import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../app.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.draft});

  final AppointmentDraft draft;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'Mastercard';
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final appState = AppScope.of(context);
    final appointment = appState.bookAppointment(draft: widget.draft);

    setState(() => _paying = false);

    // Navigate to queue tracker first — ad fires AFTER user reaches next screen
    // This ensures payment flow is never interrupted by an ad.
    if (!mounted) return;
    final adService = AdServiceProvider.of(context);
    Navigator.of(context).pushReplacementNamed(
      AppRouter.queueTracker,
      arguments: appointment,
    );

    // Show interstitial after the navigation completes (natural break point)
    await adService.showInterstitial();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ─── AppBar ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border_rounded),
                  ),
                ],
              ),
            ),

            // ─── Content ──────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space4),
                children: <Widget>[
                  // Credit card widget
                  Row(
                    children: <Widget>[
                      const Text(
                        'Credit Card',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentBlue,
                            width: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const CreditCardWidget(),
                  const SizedBox(height: 20),

                  // Summary row
                  MediQCard(
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: AppTheme.accentBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                draft.doctor.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${formatDate(draft.slotDateTime)} • ${formatTime(draft.slotDateTime)}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs ${draft.doctor.consultationFee}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Select method
                  Row(
                    children: <Widget>[
                      const Text(
                        'Select Method',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  PaymentMethodRow(
                    name: 'Visa',
                    icon: Icons.credit_card_rounded,
                    selected: _method == 'Visa',
                    onTap: () => setState(() => _method = 'Visa'),
                  ),
                  PaymentMethodRow(
                    name: 'Mastercard',
                    icon: Icons.credit_card_rounded,
                    selected: _method == 'Mastercard',
                    onTap: () => setState(() => _method = 'Mastercard'),
                  ),
                  PaymentMethodRow(
                    name: 'JazzCash',
                    icon: Icons.phone_android_rounded,
                    selected: _method == 'JazzCash',
                    onTap: () => setState(() => _method = 'JazzCash'),
                  ),
                  PaymentMethodRow(
                    name: 'EasyPaisa',
                    icon: Icons.account_balance_wallet_rounded,
                    selected: _method == 'EasyPaisa',
                    onTap: () => setState(() => _method = 'EasyPaisa'),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    '🔒 Secured payment · 256-bit SSL encryption',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ─── Fixed CTA ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space4,
                AppTheme.space3,
                AppTheme.space4,
                AppTheme.space4,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: PrimaryActionButton(
                label: _paying
                    ? 'Processing...'
                    : 'Continue — Rs ${draft.doctor.consultationFee}',
                isLoading: _paying,
                onPressed: _paying ? null : _pay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
