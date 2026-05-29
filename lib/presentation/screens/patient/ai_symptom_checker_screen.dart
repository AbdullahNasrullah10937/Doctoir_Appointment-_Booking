import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final hasSuggestions = appState.latestAiSuggestions.isNotEmpty;

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
                        Text('AI Symptom Checker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Identify possible conditions', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
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
                        const Text('Describe your symptoms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _symptomController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Fever, headache for 2 days...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Common symptoms chips
                        const Text('Common symptoms:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _commonSymptoms.map((s) => GestureDetector(
                            onTap: () {
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
                              child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 14),
                        PrimaryActionButton(
                          label: 'Analyse Symptoms',
                          icon: Icons.biotech_rounded,
                          onPressed: () => appState.runSymptomChecker(_symptomController.text),
                        ),
                      ],
                    ),
                  ),
                  // Results
                  if (hasSuggestions) ...<Widget>[
                    const SizedBox(height: 4),
                    MediQCard(
                      borderColor: AppTheme.success,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text('AI Suggested Specialists', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: appState.latestAiSuggestions.map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
                              ),
                              child: Text(s, style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                            )).toList(),
                          ),
                          const SizedBox(height: 12),
                          PrimaryActionButton(
                            label: 'Find Matching Doctors',
                            icon: Icons.search_rounded,
                            onPressed: () => Navigator.of(context).pushNamed(
                              AppRouter.doctorSearch, arguments: appState.latestAiSuggestions.first,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Disclaimer
                  MediQCard(
                    borderColor: AppTheme.warning,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'AI guidance is not a substitute for professional medical diagnosis.',
                            style: TextStyle(color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
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
