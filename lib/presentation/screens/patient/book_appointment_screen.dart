import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
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
  bool _initializedDate = false;

  final TextEditingController _reasonController = TextEditingController(
    text: 'Headache and fever for 2 days',
  );

  TimeOfDay? parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final parts = clean.split(' ');
      if (parts.length != 2) return null;
      final isPm = parts[1] == 'PM';
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (isPm && hour != 12) {
        hour += 12;
      } else if (!isPm && hour == 12) {
        hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing time: $timeStr, $e');
      return null;
    }
  }

  List<DateTime> generateSlots(DateTime date, DoctorSchedule schedule) {
    final List<DateTime> slots = [];
    final morningStart = parseTimeOfDay(schedule.morningStart);
    final morningEnd = parseTimeOfDay(schedule.morningEnd);
    final eveningStart = parseTimeOfDay(schedule.eveningStart);
    final eveningEnd = parseTimeOfDay(schedule.eveningEnd);

    void addSlots(TimeOfDay? start, TimeOfDay? end) {
      if (start == null || end == null) return;
      final startMins = start.hour * 60 + start.minute;
      final endMins = end.hour * 60 + end.minute;
      if (startMins >= endMins) return;

      for (int mins = startMins; mins < endMins; mins += 30) {
        final slotHour = mins ~/ 60;
        final slotMin = mins % 60;
        slots.add(DateTime(date.year, date.month, date.day, slotHour, slotMin));
      }
    }

    addSlots(morningStart, morningEnd);
    addSlots(eveningStart, eveningEnd);
    return slots;
  }

  DateTime findFirstSelectableDay(DoctorSchedule schedule) {
    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    DateTime day = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final checkDay = day.add(Duration(days: i));
      final dayName = weekdays[checkDay.weekday - 1];
      final dateKey = '${checkDay.year}-${checkDay.month.toString().padLeft(2, '0')}-${checkDay.day.toString().padLeft(2, '0')}';
      if (schedule.workingDays.contains(dayName) && !schedule.blockedDates.contains(dateKey)) {
        return checkDay;
      }
    }
    return DateTime.now();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _continueToPayment(DateTime slotDateTime) {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a visit reason.')),
      );
      return;
    }
    final draft = AppointmentDraft(
      doctor: widget.doctor,
      slotDateTime: slotDateTime,
      visitReason: reason,
      isVideoConsultation: _isVideo,
    );
    Navigator.of(context).pushNamed(AppRouter.payment, arguments: draft);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    return StreamBuilder<DoctorSchedule>(
      stream: appState.getDoctorScheduleStream(widget.doctor.id),
      builder: (context, scheduleSnapshot) {
        final schedule = scheduleSnapshot.data ?? DoctorSchedule.fallback(widget.doctor.id);

        if (!_initializedDate) {
          _initializedDate = true;
          final firstSelectable = findFirstSelectableDay(schedule);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedDate = firstSelectable;
                _focusedDay = firstSelectable;
              });
            }
          });
        }

        final dateKey = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

        return StreamBuilder<Map<String, String>>(
          stream: appState.getBookedSlotsStream(widget.doctor.id, dateKey),
          builder: (context, bookedSnapshot) {
            final bookedSlots = bookedSnapshot.data ?? const <String, String>{};

            final allSlots = generateSlots(_selectedDate, schedule);
            final now = DateTime.now();

            final availableSlots = allSlots.where((slot) {
              final timeLabel = formatTime(slot);
              if (bookedSlots.containsKey(timeLabel)) {
                return false;
              }
              final today = DateTime(now.year, now.month, now.day);
              final slotDay = DateTime(slot.year, slot.month, slot.day);
              if (slotDay.isAtSameMomentAs(today)) {
                if (slot.isBefore(now.add(const Duration(minutes: 10)))) {
                  return false;
                }
              }
              return true;
            }).toList();

            if (_slotIndex >= availableSlots.length) {
              _slotIndex = 0;
            }

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
                              enabledDayPredicate: (day) {
                                final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                final dayName = weekdays[day.weekday - 1];
                                if (!schedule.workingDays.contains(dayName)) {
                                  return false;
                                }
                                final checkDateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                                if (schedule.blockedDates.contains(checkDateKey)) {
                                  return false;
                                }
                                final today = DateTime.now();
                                final todayDate = DateTime(today.year, today.month, today.day);
                                final targetDate = DateTime(day.year, day.month, day.day);
                                if (targetDate.isBefore(todayDate)) {
                                  return false;
                                }
                                return true;
                              },
                              onDaySelected: (selected, focused) {
                                setState(() {
                                  _selectedDate = selected;
                                  _focusedDay = focused;
                                  _slotIndex = 0;
                                });
                              },
                              onPageChanged: (focused) {
                                setState(() {
                                  _focusedDay = focused;
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
                          if (availableSlots.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No available slots for this day. Please select another date.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List<Widget>.generate(availableSlots.length, (index) {
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
                                      formatTime(availableSlots[index]),
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
                        onPressed: availableSlots.isEmpty
                            ? null
                            : () => _continueToPayment(availableSlots[_slotIndex]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            imageAsset: doctor.imageUrl,
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
