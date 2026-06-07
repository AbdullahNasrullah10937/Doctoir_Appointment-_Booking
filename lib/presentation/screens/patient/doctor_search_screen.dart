import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key, this.initialSpecialty});
  final String? initialSpecialty;

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');
  String _specialty = 'All';
  String _gender = 'All';
  bool _todayOnly = false;

  @override
  void initState() {
    super.initState();
    _specialty = widget.initialSpecialty ?? 'All';
    _queryController.addListener(() {
      _queryNotifier.value = _queryController.text;
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final specialties = <String>{'All', ...appState.doctors.map((d) => d.specialty)}.toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // AppBar
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              color: AppTheme.surface,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Find a Doctor',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
            ),
            // Search + filters
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space3,
              ),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search doctor by name or specialty',
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Specialty chips
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: specialties.length,
                      itemBuilder: (context, index) {
                        final s = specialties[index];
                        final selected = _specialty == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _specialty = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.accentBlue : AppTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                                border: Border.all(
                                  color: selected ? AppTheme.accentBlue : AppTheme.border,
                                ),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  color: selected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Secondary filters
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const <String>['All', 'Male', 'Female']
                              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                              .toList(),
                          onChanged: (v) => setState(() => _gender = v ?? 'All'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _todayOnly = !_todayOnly),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _todayOnly ? AppTheme.primarySoft : AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: _todayOnly ? AppTheme.accentBlue : AppTheme.border,
                            ),
                          ),
                          child: Text(
                            'Available Today',
                            style: TextStyle(
                              color: _todayOnly ? AppTheme.accentBlue : AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Results
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _queryNotifier,
                builder: (context, query, child) {
                  final filteredDoctors = appState.filterDoctors(
                    query: query,
                    specialty: _specialty,
                    gender: _gender,
                    availableTodayOnly: _todayOnly,
                  );

                  if (filteredDoctors.isEmpty) {
                    return const EmptyStateView(
                      title: 'No matching doctor found',
                      message: 'Try changing your filters or search terms.',
                      icon: Icons.person_search_rounded,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.space4),
                    itemCount: filteredDoctors.length,
                    itemBuilder: (_, index) {
                      final doctor = filteredDoctors[index];
                      return MediQCard(
                        key: ValueKey<String>(doctor.id),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRouter.doctorProfile, arguments: doctor),
                        child: Row(
                          children: <Widget>[
                            AssetCircleAvatar(
                              imageAsset: doctor.imageUrl,
                              initials: buildInitials(doctor.name, fallback: 'DR'),
                              radius: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    doctor.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    doctor.specialty,
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: <Widget>[
                                      const Icon(Icons.star_rounded, color: AppTheme.warning, size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        doctor.rating.toStringAsFixed(1),
                                        style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Rs ${doctor.consultationFee}',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Next: ${doctor.nextAvailableSlot}',
                                    style: const TextStyle(color: AppTheme.accentBlue, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: doctor.isAvailableToday ? 'Available' : 'Busy',
                              color: doctor.isAvailableToday ? AppTheme.success : AppTheme.danger,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // ── Non-intrusive adaptive banner footer ──────────────────────────
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
