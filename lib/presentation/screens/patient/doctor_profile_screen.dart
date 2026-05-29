import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ─── AppBar ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              color: AppTheme.surface,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Doctor Info',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _isFavorite = !_isFavorite),
                    icon: Icon(
                      _isFavorite
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color:
                          _isFavorite ? AppTheme.danger : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  // Profile hero section
                  Container(
                    color: AppTheme.surface,
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space4,
                      AppTheme.space4,
                      AppTheme.space4,
                      AppTheme.space3,
                    ),
                    child: Column(
                      children: <Widget>[
                        // Avatar
                        AssetCircleAvatar(
                          imageAsset: doctor.imageAsset,
                          initials:
                              buildInitials(doctor.name, fallback: 'DR'),
                          radius: 48,
                          borderColor: AppTheme.primarySoft,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          doctor.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${doctor.qualifications} • ${doctor.specialty}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.star_rounded,
                              color: AppTheme.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              doctor.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.textMuted,
                              size: 15,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              doctor.location,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          children: <Widget>[
                            InfoMetricBox(
                              value: '${doctor.experienceYears}+ Yr',
                              label: 'Experience',
                            ),
                            const SizedBox(width: 8),
                            const InfoMetricBox(
                              value: '1.2K+',
                              label: 'Patients',
                            ),
                            const SizedBox(width: 8),
                            InfoMetricBox(
                              value: 'Rs ${doctor.consultationFee}',
                              label: 'Fee',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tab bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            dividerColor: Colors.transparent,
                            indicatorColor: Colors.transparent,
                            labelPadding: EdgeInsets.zero,
                            tabs: <Widget>[
                              _TabButton(
                                label: 'Information',
                                controller: _tabController,
                                index: 0,
                              ),
                              _TabButton(
                                label: 'Appointment',
                                controller: _tabController,
                                index: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab content
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        // Information tab
                        _InformationTab(doctor: doctor),
                        // Appointment tab
                        _AppointmentTab(doctor: doctor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Fixed Bottom Bar ─────────────────────────────────────────────
            BottomActionBar(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isFavorite
                                ? 'Added to favorites'
                                : 'Removed from favorites',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: _isFavorite
                          ? AppTheme.danger
                          : AppTheme.textMuted,
                    ),
                    label: Text(
                      _isFavorite ? 'Saved' : 'Add to Favorites',
                      style: TextStyle(
                        color: _isFavorite
                            ? AppTheme.danger
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.bookAppointment,
                        arguments: doctor,
                      );
                    },
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom tab button ────────────────────────────────────────────────────────

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.label,
    required this.controller,
    required this.index,
  });

  final String label;
  final TabController controller;
  final int index;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.controller.index == widget.index;
    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Information tab ──────────────────────────────────────────────────────────

class _InformationTab extends StatelessWidget {
  const _InformationTab({required this.doctor});
  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Personal bio
          const Text(
            'Personal Bio',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            '${doctor.name} is a highly experienced ${doctor.specialty} specialist with over ${doctor.experienceYears} years of expertise. They are known for patient-first care at ${doctor.hospital}.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.6,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Appointment time info
          const Text(
            'Appointment Time',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _InfoChip(
                icon: Icons.calendar_today_rounded,
                label: 'Mon – Fri',
              ),
              const SizedBox(width: 10),
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: '10:00am–5:00pm',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Reviews
          const Text(
            'Patient Reviews',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          if (doctor.reviews.isEmpty)
            const Text(
              'No reviews yet.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            ...doctor.reviews.take(2).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MediQCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(AppTheme.space3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                r.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.star_rounded,
                                color: AppTheme.warning,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                r.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${r.comment}"',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Appointment tab ──────────────────────────────────────────────────────────

class _AppointmentTab extends StatelessWidget {
  const _AppointmentTab({required this.doctor});
  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Consultation Details',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.local_hospital_rounded,
            label: 'Hospital',
            value: doctor.hospital,
          ),
          _DetailRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: doctor.location,
          ),
          _DetailRow(
            icon: Icons.payments_rounded,
            label: 'Consultation Fee',
            value: 'Rs ${doctor.consultationFee}',
          ),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: 'Next Available',
            value: doctor.nextAvailableSlot,
          ),
          _DetailRow(
            icon: Icons.wc_rounded,
            label: 'Gender',
            value: doctor.gender,
          ),
        ],
      ),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppTheme.accentBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppTheme.accentBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
