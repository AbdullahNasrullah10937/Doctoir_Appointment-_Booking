import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../widgets/common_widgets.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  int _slotIndex = 0;
  bool _isVideo = false;
  final TextEditingController _reasonController = TextEditingController(
    text: 'Headache and fever for 2 days',
  );

  List<DateTime> get _slots {
    final d = _selectedDate;
    final base = DateTime(d.year, d.month, d.day);
    return <DateTime>[
      base.add(const Duration(hours: 10)),
      base.add(const Duration(hours: 10, minutes: 15)),
      base.add(const Duration(hours: 10, minutes: 30)),
      base.add(const Duration(hours: 11)),
      base.add(const Duration(hours: 11, minutes: 30)),
      base.add(const Duration(hours: 12)),
      base.add(const Duration(hours: 14)),
      base.add(const Duration(hours: 14, minutes: 30)),
      base.add(const Duration(hours: 15)),
      base.add(const Duration(hours: 16)),
    ];
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _continueToPayment() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a visit reason.')),
      );
      return;
    }
    final draft = AppointmentDraft(
      doctor: widget.doctor,
      slotDateTime: _slots[_slotIndex],
      visitReason: reason,
      isVideoConsultation: _isVideo,
    );
    Navigator.of(context).pushNamed(AppRouter.payment, arguments: draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ─── Custom AppBar ────────────────────────────────────────────────
            _BookingAppBar(doctorName: widget.doctor.name),

            // ─── Scrollable content ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space4,
                  vertical: AppTheme.space3,
                ),
                children: <Widget>[
                  // Doctor mini card
                  _DoctorMiniCard(doctor: widget.doctor),
                  const SizedBox(height: 4),

                  // Calendar section
                  _SectionLabel(label: 'Select Date'),
                  MediQCard(
                    padding: EdgeInsets.zero,
                    child: TableCalendar<void>(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 60)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDate, day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDate = selected;
                          _focusedDay = focused;
                          _slotIndex = 0;
                        });
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.w700,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppTheme.accentBlue,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        weekendTextStyle:
                            TextStyle(color: AppTheme.danger),
                        outsideDaysVisible: false,
                        cellMargin: EdgeInsets.all(4),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppTheme.accentBlue,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.accentBlue,
                        ),
                        headerPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        weekendStyle: TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Time slots
                  _SectionLabel(label: 'Select Time Slot'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(_slots.length, (index) {
                      final selected = index == _slotIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _slotIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.accentBlue
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.accentBlue
                                  : AppTheme.border,
                            ),
                          ),
                          child: Text(
                            formatTime(_slots[index]),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Visit reason
                  _SectionLabel(label: 'Visit Reason'),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe your symptoms briefly...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Video consultation toggle
                  MediQCard(
                    margin: EdgeInsets.zero,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            color: AppTheme.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Video Consultation',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Consult remotely from home',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isVideo,
                          onChanged: (v) => setState(() => _isVideo = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ─── Fixed bottom CTA ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space4,
                AppTheme.space3,
                AppTheme.space4,
                AppTheme.space4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: const Border(
                  top: BorderSide(color: AppTheme.border),
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: PrimaryActionButton(
                label: 'Confirm Booking',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _continueToPayment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom AppBar ────────────────────────────────────────────────────────────

class _BookingAppBar extends StatelessWidget {
  const _BookingAppBar({required this.doctorName});
  final String doctorName;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Book Appointment',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                Text(
                  doctorName,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
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

// ─── Doctor Mini Card ─────────────────────────────────────────────────────────

class _DoctorMiniCard extends StatelessWidget {
  const _DoctorMiniCard({required this.doctor});
  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return MediQCard(
      child: Row(
        children: <Widget>[
          AssetCircleAvatar(
            imageAsset: doctor.imageAsset,
            initials: doctor.name.isNotEmpty ? doctor.name[0] : 'D',
            radius: 24,
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
                Text(
                  doctor.specialty,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              'Rs ${doctor.consultationFee}',
              style: const TextStyle(
                color: AppTheme.accentBlue,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppTheme.space2,
        top: AppTheme.space3,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
