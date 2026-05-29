import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class RateReviewScreen extends StatefulWidget {
  const RateReviewScreen({super.key, this.doctor});
  final Doctor? doctor;

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _rating = 4;
  final TextEditingController _commentController = TextEditingController(
    text: 'Doctor explained the issue clearly and was very patient.',
  );

  final List<String> _tags = <String>[
    'Friendly', 'Professional', 'On Time', 'Clear Explanation', 'Thorough',
  ];
  final Set<String> _selectedTags = <String>{'Friendly', 'Professional'};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted. Thank you!')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.patientShell, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Rate & Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Your feedback helps others', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space4),
                children: <Widget>[
                  // Doctor card
                  MediQCard(
                    child: Column(
                      children: <Widget>[
                        AssetCircleAvatar(
                          imageAsset: doctor?.imageAsset,
                          initials: buildInitials(doctor?.name ?? 'Doctor', fallback: 'DR'),
                          radius: 36,
                          borderColor: AppTheme.accentBlue,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          doctor?.name ?? 'Doctor',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        if (doctor != null) ...<Widget>[
                          const SizedBox(height: 3),
                          Text(doctor.specialty, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                        const SizedBox(height: 16),
                        // Star row
                        const Text('How was your experience?',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(5, (index) {
                            final pos = index + 1;
                            return GestureDetector(
                              onTap: () => setState(() => _rating = pos),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    pos <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    key: ValueKey<bool>(pos <= _rating),
                                    color: AppTheme.warning,
                                    size: 40,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _rating == 5 ? 'Excellent!' : _rating == 4 ? 'Very Good' : _rating == 3 ? 'Good' : _rating == 2 ? 'Fair' : 'Poor',
                          style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // Tags
                  MediQCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('What did you like?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _tags.map((tag) {
                            final selected = _selectedTags.contains(tag);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedTags.remove(tag);
                                } else {
                                  _selectedTags.add(tag);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.accentBlue : AppTheme.surfaceAlt,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                                  border: Border.all(color: selected ? AppTheme.accentBlue : AppTheme.border),
                                ),
                                child: Text(tag, style: TextStyle(
                                  color: selected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600, fontSize: 13,
                                )),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Comment box
                  MediQCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _commentController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Share your experience...',
                          ),
                        ),
                      ],
                    ),
                  ),
                  PrimaryActionButton(
                    label: 'Submit Review',
                    icon: Icons.send_rounded,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
