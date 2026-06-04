import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../app.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

class AiSymptomCheckerScreen extends StatefulWidget {
  const AiSymptomCheckerScreen({super.key});

  @override
  State<AiSymptomCheckerScreen> createState() => _AiSymptomCheckerScreenState();
}

class _AiSymptomCheckerScreenState extends State<AiSymptomCheckerScreen> {
  final TextEditingController _symptomController = TextEditingController(
    text: 'Fever, sore throat, headache for 2 days',
  );

  final List<String> _commonSymptoms = <String>[
    'Headache', 'Fever', 'Cough', 'Fatigue', 'Chest Pain',
    'Nausea', 'Back Pain', 'Rash', 'Dizziness',
  ];

  // Rewarded ad state — unlocks Extended AI Analysis section
  bool _extendedAnalysisUnlocked = false;
  bool _isShowingRewardedAd = false;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'EMERGENCY':
        return AppTheme.danger;
      case 'URGENT':
        return AppTheme.warning;
      case 'NON_URGENT':
        return AppTheme.accentBlue;
      case 'SELF_CARE':
        return AppTheme.success;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getUrgencyIcon(String urgency) {
    switch (urgency) {
      case 'EMERGENCY':
        return Icons.gpp_bad_rounded;
      case 'URGENT':
        return Icons.warning_amber_rounded;
      case 'NON_URGENT':
        return Icons.info_outline_rounded;
      case 'SELF_CARE':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final hasSuggestions = appState.latestAiSuggestions.isNotEmpty &&
        appState.triageUrgency.isNotEmpty;

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
                        Text(
                          'AI Symptom Checker',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text('Identify possible conditions securely', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space4),
                children: <Widget>[
                  // Input card
                  MediQCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Describe your symptoms',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _symptomController,
                          maxLines: 3,
                          enabled: !appState.isSymptomCheckerLoading,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Fever, headache for 2 days...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Common symptoms chips
                        const Text(
                          'Common symptoms:',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _commonSymptoms.map((s) => GestureDetector(
                            onTap: appState.isSymptomCheckerLoading
                                ? null
                                : () {
                                    final current = _symptomController.text;
                                    if (!current.contains(s)) {
                                      _symptomController.text = current.isEmpty ? s : '$current, $s';
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                        if (appState.isSymptomCheckerLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(strokeWidth: 3),
                                  SizedBox(height: 8),
                                  Text(
                                    'Analyzing symptoms with Qurexa AI...',
                                    style: TextStyle(
                                      color: AppTheme.accentBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          PrimaryActionButton(
                            label: 'Analyse Symptoms',
                            icon: Icons.biotech_rounded,
                            onPressed: () {
                              if (_symptomController.text.trim().isNotEmpty) {
                                appState.runSymptomChecker(_symptomController.text);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Structured Results Card
                  if (hasSuggestions && !appState.isSymptomCheckerLoading) ...[
                    MediQCard(
                      borderColor: _getUrgencyColor(appState.triageUrgency),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Urgency Indicator Badge
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getUrgencyColor(appState.triageUrgency).withValues(alpha: 0.15),
                                child: Icon(
                                  _getUrgencyIcon(appState.triageUrgency),
                                  color: _getUrgencyColor(appState.triageUrgency),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Triage Level: ${appState.triageUrgency}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: _getUrgencyColor(appState.triageUrgency),
                                    ),
                                  ),
                                  const Text(
                                    'AI Safety Triage Assessment',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),

                          // Triage Summary Notes
                          const Text(
                            'Reported Symptoms Summary',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.triageSummary,
                            style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 14),

                          // Triage Rationalization
                          const Text(
                            'Clinical Assessment',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.triageRationalization,
                            style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 14),

                          // AI Suggested Specialties & deep link searches
                          if (appState.triageSpecialties.isNotEmpty) ...[
                            const Text(
                              'AI Suggested Specialist Fields',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: appState.triageSpecialties.map((s) {
                                return ActionChip(
                                  label: Text(s),
                                  labelStyle: const TextStyle(
                                    color: AppTheme.accentBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  backgroundColor: AppTheme.primarySoft,
                                  side: BorderSide(color: AppTheme.accentBlue.withValues(alpha: 0.2)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  onPressed: () => Navigator.of(context).pushNamed(
                                    AppRouter.doctorSearch,
                                    arguments: s,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Cautious possible conditions
                          if (appState.triageConditions.isNotEmpty) ...[
                            const Text(
                              'Differential Hypotheses (Caution)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: appState.triageConditions.map((cond) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Expanded(
                                        child: Text(
                                          cond,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Follow up questions to discuss with doctor
                          if (appState.triageFollowUps.isNotEmpty) ...[
                            const Text(
                              'Follow-up Questions to Ask Your Doctor',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: appState.triageFollowUps.map((q) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('? ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
                                        Expanded(
                                          child: Text(
                                            q,
                                            style: const TextStyle(fontSize: 12, height: 1.35),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Quick Search Doctor Button
                          PrimaryActionButton(
                            label: 'Find Matching Doctors Now',
                            icon: Icons.search_rounded,
                            onPressed: () => Navigator.of(context).pushNamed(
                              AppRouter.doctorSearch,
                              arguments: appState.latestAiSuggestions.first,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Rewarded Ad: Extended AI Analysis ────────────────────
                    if (!_extendedAnalysisUnlocked)
                      MediQCard(
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentBlue, size: 22),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Unlock Extended Analysis',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                      Text(
                                        'Get deeper AI health insights, prevention tips, and a full health risk report.',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _isShowingRewardedAd
                                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        ),
                                      ),
                                      icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                                      label: const Text(
                                        'Watch a short ad to unlock',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      onPressed: () async {
                                        setState(() => _isShowingRewardedAd = true);
                                        await AdServiceProvider.of(context).showRewarded(
                                          onEarnReward: () {
                                            if (mounted) {
                                              setState(() => _extendedAnalysisUnlocked = true);
                                            }
                                          },
                                          onDone: () {
                                            if (mounted) {
                                              setState(() => _isShowingRewardedAd = false);
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      )
                    else
                      // ── Extended Analysis (unlocked after reward) ─────────
                      MediQCard(
                        borderColor: AppTheme.accentBlue,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentBlue, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Extended AI Health Insights',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.accentBlue),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            const Text(
                              'Lifestyle & Prevention Tips',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Based on your symptoms, maintaining hydration, adequate rest, and monitoring temperature changes can help manage your condition. Avoid strenuous activity and seek emergency care if symptoms worsen significantly.',
                              style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Risk Factors to Monitor',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Patients with pre-existing respiratory or immune conditions should seek evaluation sooner. Track symptom progression daily and note any new developments before your doctor visit.',
                              style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.verified_rounded, color: AppTheme.accentBlue, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Extended analysis unlocked',
                                    style: TextStyle(fontSize: 11, color: AppTheme.accentBlue, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],

                  // Disclaimer Card
                  MediQCard(
                    borderColor: AppTheme.warning,
                    child: const Row(
                      children: <Widget>[
                        Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI guidance is not a substitute for professional medical diagnosis. Always consult a real doctor.',
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  SecondaryActionButton(
                    label: 'Open AI Health Chat',
                    icon: Icons.chat_rounded,
                    onPressed: () => Navigator.of(context).pushNamed(AppRouter.aiAssistant),
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
