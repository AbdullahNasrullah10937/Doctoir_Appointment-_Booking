import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firebase_paths.dart';
import '../../core/security/emergency_parser.dart';
import '../../core/ai/services/ai_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/firebase/app_rtdb_codecs.dart';
import '../../data/firebase/appointment_rtdb_codec.dart';
import '../../data/firebase/doctor_application_sync.dart';
import '../../data/firebase/patient_cloud_sync.dart';
import '../../data/repositories/mock_app_repository.dart';
import '../../domain/entities/app_entities.dart';
import '../../domain/entities/doctor_application.dart';
import '../../domain/entities/role_mismatch_exception.dart';
import '../../domain/repositories/app_repository.dart';
import '../widgets/screen_helpers.dart';

class AppState extends ChangeNotifier {
  AppState({AppRepository? repository})
    : _repository = repository ?? MockAppRepository();

  final AppRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final DoctorCatalogCloudRepository _doctorCatalogRepo =
      DoctorCatalogCloudRepository();
  final PatientAppointmentCloudRepository _appointmentRepo =
      PatientAppointmentCloudRepository();
  final PatientRecordCloudRepository _recordRepo =
      PatientRecordCloudRepository();
  final PatientReminderCloudRepository _reminderRepo =
      PatientReminderCloudRepository();
  final PatientNotificationCloudRepository _notificationRepo =
      PatientNotificationCloudRepository();
  final PatientQueueCloudRepository _queueRepo = PatientQueueCloudRepository();
  final DoctorQueueCloudRepository _doctorQueueRepo =
      DoctorQueueCloudRepository();
  final DoctorScheduleCloudRepository _doctorScheduleRepo =
      DoctorScheduleCloudRepository();
  final PatientPrescriptionCloudRepository _prescriptionRepo =
      PatientPrescriptionCloudRepository();

  final DoctorApplicationRepository _doctorApplicationRepo =
      DoctorApplicationRepository();

  StreamSubscription<List<Doctor>>? _doctorCatalogSub;
  StreamSubscription<List<Appointment>>? _appointmentsSub;
  StreamSubscription<List<HealthRecord>>? _recordsSub;
  StreamSubscription<List<MedicationReminder>>? _remindersSub;
  StreamSubscription<List<AppNotification>>? _notificationsSub;
  StreamSubscription<QueueSnapshot?>? _queueSnapshotSub;
  StreamSubscription<List<PatientCase>>? _doctorQueueSub;
  StreamSubscription<DoctorSchedule?>? _doctorScheduleSub;
  StreamSubscription<List<DoctorApplication>>? _adminApplicationsSub;

  final AiService _aiService = AiService();

  List<ChatMessage> aiChatHistory = <ChatMessage>[
    const ChatMessage(
      text: 'Hello! I\'m your Qurexa AI Health Assistant. Ask me anything about your symptoms or health concerns.',
      isUser: false,
    ),
  ];
  bool isAiAssistantTyping = false;
  bool showEmergencyBanner = false;

  // Symptom Checker Triage State
  bool isSymptomCheckerLoading = false;
  String? symptomCheckerError;
  String triageSummary = '';
  String triageUrgency = ''; // EMERGENCY, URGENT, NON_URGENT, SELF_CARE
  String triageRationalization = '';
  List<String> triageSpecialties = <String>[];
  List<String> triageFollowUps = <String>[];
  List<String> triageConditions = <String>[];

  String? firebaseUserId;

  bool initialized = false;
  bool isBootstrapping = false;

  bool seenOnboarding = false;
  bool isLoggedIn = false;
  bool profileCompleted = false;

  bool _appDataLoaded = false;
  bool _loadingAppData = false;

  bool get appDataLoaded => _appDataLoaded;
  bool get loadingAppData => _loadingAppData;

  UserRole role = UserRole.patient;
  UserProfile? profile;

  int patientTabIndex = 0;
  int doctorTabIndex = 0;

  bool doctorNotificationsEnabled = true;
  String doctorLanguage = 'English';
  bool doctorPrivacyModeEnabled = true;

  List<Doctor> doctors = <Doctor>[];
  List<Appointment> appointments = <Appointment>[];
  List<HealthRecord> records = <HealthRecord>[];
  List<MedicationReminder> reminders = <MedicationReminder>[];
  List<AppNotification> notifications = <AppNotification>[];
  List<PatientCase> doctorQueue = <PatientCase>[];
  List<DoctorApplication> doctorApplications = <DoctorApplication>[];
  DoctorApplication? currentDoctorApplication;
  DoctorVerificationStatus doctorVerificationStatus =
      DoctorVerificationStatus.pending;
  DoctorSchedule doctorSchedule = const DoctorSchedule(
    workingDays: <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    morningStart: '9:00 AM',
    morningEnd: '1:00 PM',
    eveningStart: '5:00 PM',
    eveningEnd: '8:00 PM',
  );
  QueueSnapshot? queueSnapshot;

  List<String> latestAiSuggestions = <String>[];

  Appointment? get nextUpcomingAppointment {
    final upcoming =
        appointments
            .where(
              (appointment) => appointment.status == AppointmentStatus.upcoming,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (upcoming.isEmpty) {
      return null;
    }

    return upcoming.first;
  }

  List<Appointment> get upcomingAppointments {
    final list =
        appointments
            .where(
              (appointment) => appointment.status == AppointmentStatus.upcoming,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  List<Appointment> get pastAppointments {
    final list =
        appointments
            .where(
              (appointment) =>
                  appointment.status == AppointmentStatus.completed,
            )
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  int get unreadNotificationCount {
    return notifications.where((item) => item.isUnread).length;
  }

  Future<void> initialize() async {
    if (initialized || isBootstrapping) {
      return;
    }

    isBootstrapping = true;
    notifyListeners();

    // Critical startup path: only restore user session
    await _restoreFirebaseSession();

    initialized = true;
    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> loadAppData() async {
    // When Firebase is enabled all data arrives via real-time listeners started
    // in _startRealtimeListeners(). There is nothing to load from the repository.
    if (FirebaseBootstrap.enabled) {
      _appDataLoaded = true;
      return;
    }

    if (_appDataLoaded || _loadingAppData) return;

    _loadingAppData = true;
    notifyListeners();

    try {
      // Offline / dev-mode only — repository is MockAppRepository in this path.
      final results = await Future.wait([
        _repository.getDoctors(),
        _repository.getAppointments(),
        _repository.getHealthRecords(),
        _repository.getMedicationReminders(),
        _repository.getNotifications(),
        _repository.getDoctorQueue(),
        _repository.getDoctorSchedule(),
        _repository.getQueueSnapshot(),
      ]);

      doctors = results[0] as List<Doctor>;
      appointments = results[1] as List<Appointment>;
      records = results[2] as List<HealthRecord>;
      reminders = results[3] as List<MedicationReminder>;
      notifications = results[4] as List<AppNotification>;
      doctorQueue = results[5] as List<PatientCase>;
      doctorSchedule = results[6] as DoctorSchedule;
      queueSnapshot = results[7] as QueueSnapshot?;

      _appDataLoaded = true;
    } catch (e) {
      debugPrint('[AppState] App data loading failed (non-fatal): $e');
    } finally {
      _loadingAppData = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required UserRole selectedRole,
    required String email,
    required String password,
  }) async {
    if (!FirebaseBootstrap.enabled) {
      role = selectedRole;
      isLoggedIn = true;
      profileCompleted = selectedRole == UserRole.doctor || profile != null;
      notifyListeners();
      return;
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _attachFirebaseUser(
      credential.user,
      roleOverride: selectedRole,
      isNewUser: false,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    UserRole roleOverride = UserRole.patient,
  }) async {
    if (!FirebaseBootstrap.enabled) {
      role = roleOverride;
      isLoggedIn = true;
      profileCompleted = roleOverride == UserRole.doctor || profile != null;
      notifyListeners();
      return;
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _attachFirebaseUser(
      credential.user,
      roleOverride: roleOverride,
      isNewUser: true,
    );
  }

  /// Updates AppState after the DoctorSignupScreen completes registration.
  /// Auth account creation, uploads, and RTDB writes are done in the screen.
  void setDoctorRegistered(DoctorApplication app) {
    firebaseUserId = app.uid;
    role = UserRole.doctor;
    doctorVerificationStatus = DoctorVerificationStatus.pending;
    currentDoctorApplication = app;
    isLoggedIn = true;
    profileCompleted = true;
    notifyListeners();
  }

  Future<void> loadAdminData() async {
    if (!FirebaseBootstrap.enabled) return;
    _adminApplicationsSub?.cancel();
    _adminApplicationsSub =
        _doctorApplicationRepo.listenAllApplications().listen((apps) {
      doctorApplications = apps;
      notifyListeners();
    });
  }

  Future<void> approveDoctorApplication(String uid) async {
    await _doctorApplicationRepo.approveDoctor(uid);
    doctorApplications = doctorApplications.map((app) {
      if (app.uid == uid) return app.copyWith(status: DoctorVerificationStatus.approved);
      return app;
    }).toList();
    notifyListeners();
  }

  Future<void> rejectDoctorApplication(
      String uid, String reason) async {
    await _doctorApplicationRepo.rejectDoctor(uid, reason: reason);
    doctorApplications = doctorApplications.map((app) {
      if (app.uid == uid) {
        return app.copyWith(
            status: DoctorVerificationStatus.rejected,
            rejectionReason: reason);
      }
      return app;
    }).toList();
    notifyListeners();
  }

  Future<void> resubmitDoctorApplication(DoctorApplication updated) async {
    await _doctorApplicationRepo.resubmitApplication(updated);
    currentDoctorApplication =
        updated.copyWith(status: DoctorVerificationStatus.pending);
    doctorVerificationStatus = DoctorVerificationStatus.pending;
    notifyListeners();
  }

  Future<void> loginWithGoogle({required UserRole selectedRole}) async {
    if (!FirebaseBootstrap.enabled) {
      role = selectedRole;
      isLoggedIn = true;
      profileCompleted = selectedRole == UserRole.doctor || profile != null;
      notifyListeners();
      return;
    }

    try {
      // Force account selection screen by clearing any existing system-level Google client session
      await _googleSignIn.signOut().catchError((_) => null);
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the Google sign-in flow
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      await _attachFirebaseUser(
        userCredential.user,
        roleOverride: selectedRole,
        isNewUser: isNew,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'This email is already registered under another sign-in method. '
          'Please sign in using your email and password.'
        );
      }
      rethrow;
    }
  }

  Future<bool> resumeSession({UserRole? roleOverride}) async {
    final user = _auth.currentUser;
    if (!FirebaseBootstrap.enabled || user == null) {
      return false;
    }

    await _attachFirebaseUser(
      user,
      roleOverride: roleOverride,
      isNewUser: false,
    );
    return true;
  }

  void completeOnboarding() {
    seenOnboarding = true;
    notifyListeners();
  }

  void completeProfile(UserProfile value) {
    profile = value;
    profileCompleted = true;
    if (FirebaseBootstrap.enabled) {
      unawaited(PatientCloudBootstrap.writeProfileSnapshot(profile: value));
    }
    notifyListeners();
  }

  void logout() {
    _stopRealtimeListeners();
    if (FirebaseBootstrap.enabled) {
      unawaited(_auth.signOut());
      unawaited(_googleSignIn.signOut());
    }
    firebaseUserId = null;
    isLoggedIn = false;
    role = UserRole.patient;
    patientTabIndex = 0;
    doctorTabIndex = 0;
    latestAiSuggestions = <String>[];
    doctorVerificationStatus = DoctorVerificationStatus.pending;
    currentDoctorApplication = null;
    doctorApplications = <DoctorApplication>[];
    notifyListeners();
  }

  void setPatientTab(int index) {
    patientTabIndex = index;
    notifyListeners();
  }

  void setDoctorTab(int index) {
    doctorTabIndex = index;
    notifyListeners();
  }

  void setDoctorNotificationsEnabled(bool value) {
    doctorNotificationsEnabled = value;
    notifyListeners();
  }

  void setDoctorLanguage(String value) {
    doctorLanguage = value;
    notifyListeners();
  }

  void setDoctorPrivacyModeEnabled(bool value) {
    doctorPrivacyModeEnabled = value;
    notifyListeners();
  }

  Future<void> _restoreFirebaseSession() async {
    if (!FirebaseBootstrap.enabled) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await _attachFirebaseUser(user, isNewUser: false);
  }

  Future<void> _attachFirebaseUser(
    User? user, {
    UserRole? roleOverride,
    bool isNewUser = false,
  }) async {
    if (user == null) {
      return;
    }

    firebaseUserId = user.uid;
    final restored = await PatientCloudBootstrap.tryRestore();
    if (restored == null) {
      throw Exception("Database synchronization failed.");
    }

    UserRole resolvedRole;

    switch (restored.metaState) {
      case MetaState.fetchFailed:
        throw Exception('Database connection lost. Please try again.');

      case MetaState.found:
        // ── Strict role enforcement ───────────────────────────────────────
        // storedRole is the single source of truth. If the caller supplied a
        // roleOverride (i.e. the user selected a role on the login page) and
        // it differs from what is permanently stored, reject the attempt.
        // Special case: admin users bypass this check.
        final storedRole = restored.restoredRole;
        if (storedRole != UserRole.admin && roleOverride != null && roleOverride != storedRole) {
          throw RoleMismatchException(
            selectedRole: roleOverride,
            registeredRole: storedRole,
          );
        }
        resolvedRole = storedRole;
        break;

      case MetaState.notFound:
        // ── New-user registration path ────────────────────────────────────
        // Treat both isNewUser==true AND isNewUser==false (Firebase OAuth
        // inconsistency) as a first-time registration — write the selected
        // role and continue normally.
        resolvedRole = roleOverride ?? UserRole.patient;
        final committed = await PatientCloudBootstrap.writeRoleMeta(
          firebaseUserId: user.uid,
          role: resolvedRole,
        );
        if (!committed) {
          // Transaction aborted — another write already locked the role.
          // Re-fetch to get the actual stored value.
          final fallback = await PatientCloudBootstrap.tryRestore();
          if (fallback?.metaState == MetaState.found) {
            final fallbackRole = fallback!.restoredRole;
            if (fallbackRole != UserRole.admin && roleOverride != null && roleOverride != fallbackRole) {
              throw RoleMismatchException(
                selectedRole: roleOverride,
                registeredRole: fallbackRole,
              );
            }
            resolvedRole = fallbackRole;
          } else {
            throw Exception(
              'Failed to initialize account role securely. Please try again.',
            );
          }
        }
        break;
    }

    role = resolvedRole;
    profile = restored.profile ?? profile;
    isLoggedIn = true;
    profileCompleted =
        role == UserRole.doctor || role == UserRole.admin || profile != null;

    // Read doctor verification status from bootstrap snapshot
    if (role == UserRole.doctor) {
      final statusRaw = restored.verificationStatus;
      doctorVerificationStatus = DoctorVerificationStatus.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => DoctorVerificationStatus.pending,
      );
      // Load the doctor's own application data
      final uid = firebaseUserId;
      if (uid != null && FirebaseBootstrap.enabled) {
        unawaited(_doctorApplicationRepo
            .getApplicationForUser(uid)
            .then((app) {
          currentDoctorApplication = app;
          notifyListeners();
        }));
      }
    }

    _startRealtimeListeners();
    notifyListeners();
  }

  void _startRealtimeListeners() {
    _stopRealtimeListeners();
    final uid = firebaseUserId;
    if (!FirebaseBootstrap.enabled || uid == null) {
      return;
    }

    _doctorCatalogSub = _doctorCatalogRepo.listenCatalog().listen((items) {
      // Always replace with Firebase data — even an empty list means no approved
      // doctors yet. Never fall back to stale mock data.
      doctors = items;
      notifyListeners();
    });

    _appointmentsSub = _appointmentRepo
        .listenAppointments(catalog: doctors, firebaseUid: uid)
        .listen((items) {
          appointments = items;
          notifyListeners();
        });

    _recordsSub = _recordRepo.listenRecords(firebaseUid: uid).listen((items) {
      records = items;
      notifyListeners();
    });

    _remindersSub = _reminderRepo.listenReminders(firebaseUid: uid).listen((
      items,
    ) {
      reminders = items;
      notifyListeners();
    });

    // First emission silently loads existing notifications (no system popups).
    // Subsequent emissions only fire popups for genuinely new unread items.
    bool isFirstBatch = true;
    _notificationsSub = _notificationRepo
        .listenNotifications(firebaseUid: uid)
        .listen((items) {
          if (isFirstBatch) {
            isFirstBatch = false;
          } else {
            // Only trigger system popups for items that just appeared.
            final oldIds = notifications.map((n) => n.id).toSet();
            for (final item in items) {
              if (item.isUnread && !oldIds.contains(item.id)) {
                unawaited(
                  NotificationService.instance.showNotification(
                    id: item.id.hashCode,
                    title: item.title,
                    body: item.message,
                  ),
                );
              }
            }
          }
          notifications = items;
          notifyListeners();
        });

    if (role == UserRole.doctor) {
      _doctorQueueSub = _doctorQueueRepo.listenQueue(firebaseUid: uid).listen((
        items,
      ) {
        doctorQueue = items;
        notifyListeners();
      });

      _doctorScheduleSub = _doctorScheduleRepo
          .listenSchedule(firebaseUid: uid)
          .listen((value) {
            if (value != null) {
              doctorSchedule = value;
              notifyListeners();
            }
          });
    } else {
      _queueSnapshotSub = _queueRepo.listenQueue(firebaseUid: uid).listen((
        snapshot,
      ) {
        queueSnapshot = snapshot;
        notifyListeners();
      });
    }

  }

  void _stopRealtimeListeners() {
    _doctorCatalogSub?.cancel();
    _appointmentsSub?.cancel();
    _recordsSub?.cancel();
    _remindersSub?.cancel();
    _notificationsSub?.cancel();
    _queueSnapshotSub?.cancel();
    _doctorQueueSub?.cancel();
    _doctorScheduleSub?.cancel();
    _adminApplicationsSub?.cancel();
    _doctorCatalogSub = null;
    _appointmentsSub = null;
    _recordsSub = null;
    _remindersSub = null;
    _notificationsSub = null;
    _queueSnapshotSub = null;
    _doctorQueueSub = null;
    _doctorScheduleSub = null;
    _adminApplicationsSub = null;

    // Clear chat history on logout
    aiChatHistory = <ChatMessage>[
      const ChatMessage(
        text: 'Hello! I\'m your Qurexa AI Health Assistant. Ask me anything about your symptoms or health concerns.',
        isUser: false,
      ),
    ];
    showEmergencyBanner = false;
  }

  List<Doctor> filterDoctors({
    String query = '',
    String specialty = 'All',
    String gender = 'All',
    bool availableTodayOnly = false,
  }) {
    return doctors.where((doctor) {
      final queryMatch =
          query.trim().isEmpty ||
          doctor.name.toLowerCase().contains(query.toLowerCase()) ||
          doctor.specialty.toLowerCase().contains(query.toLowerCase());

      final specialtyMatch =
          specialty == 'All' || doctor.specialty == specialty;

      final genderMatch = gender == 'All' || doctor.gender == gender;

      final availabilityMatch =
          !availableTodayOnly || doctor.isAvailableToday == true;

      return queryMatch && specialtyMatch && genderMatch && availabilityMatch;
    }).toList();
  }

  Future<Appointment> bookAppointment({required AppointmentDraft draft}) async {
    final token = 12 + Random().nextInt(10);
    final now = DateTime.now().millisecondsSinceEpoch;
    final appointmentId = 'a_$now';

    final appointment = Appointment(
      id: appointmentId,
      doctor: draft.doctor,
      dateTime: draft.slotDateTime,
      tokenNumber: token,
      status: AppointmentStatus.upcoming,
      visitReason: draft.visitReason,
      isVideoConsultation: draft.isVideoConsultation,
    );

    final localQueueSnapshot = QueueSnapshot(
      doctorName: draft.doctor.name,
      doctorId: draft.doctor.id,
      clinicLocation: draft.doctor.hospital,
      yourToken: token,
      currentToken: token - 4,
      patientsAhead: 4,
      estimatedWaitMinutes: 25,
    );

    if (FirebaseBootstrap.enabled) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        // Build a PatientCase to insert into the doctor's live queue.
        final patientCase = PatientCase(
          id: appointmentId,
          patientName: profile?.fullName ?? 'Patient',
          age: profile?.age ?? 0,
          gender: profile?.gender ?? 'Unknown',
          token: token,
          symptoms: draft.visitReason,
          conditions: const <String>[],
          patientUid: uid,
        );

        final dateKey = _formatDateKey(draft.slotDateTime);
        final timeLabel = _formatTimeOfDay(draft.slotDateTime);

        // Single atomic multi-path write — prevents partial state:
        // 1. appointment under patient's private path
        // 2. queue snapshot for the patient
        // 3. patient case in the doctor's queue
        // 4. booked slot lock under doctor's node
        final Map<String, dynamic> atomicUpdate = <String, dynamic>{
          '${FirebasePaths.appointments(uid)}/$appointmentId':
              AppointmentRtdbCodec.encode(appointment),
          FirebasePaths.queueSnapshot(uid):
              QueueSnapshotRtdbCodec.encode(localQueueSnapshot),
          '${FirebasePaths.doctorQueue(draft.doctor.id)}/$appointmentId':
              PatientCaseRtdbCodec.encode(patientCase),
          'doctors/${draft.doctor.id}/booked_slots/$dateKey/$timeLabel': uid,
        };
        await _db.ref().update(atomicUpdate);
      }
    }

    appointments = <Appointment>[appointment, ...appointments];
    queueSnapshot = localQueueSnapshot;

    _addNotification(
      AppNotification(
        id: 'n_$now',
        title: 'Booking Confirmed',
        message: 'Token #$token for ${draft.doctor.name} is confirmed.',
        type: NotificationType.appointment,
        timeLabel: 'Just now',
      ),
    );

    notifyListeners();
    return appointment;
  }

  void cancelAppointment(String appointmentId) {
    appointments = appointments.map((appointment) {
      if (appointment.id != appointmentId) {
        return appointment;
      }

      return appointment.copyWith(status: AppointmentStatus.cancelled);
    }).toList();

    if (FirebaseBootstrap.enabled) {
      unawaited(
        _appointmentRepo.mergeStatus(
          appointmentId: appointmentId,
          status: AppointmentStatus.cancelled,
        ),
      );
    }

    notifyListeners();
  }

  void completeAppointment(String appointmentId) {
    appointments = appointments.map((appointment) {
      if (appointment.id != appointmentId) {
        return appointment;
      }

      return appointment.copyWith(status: AppointmentStatus.completed);
    }).toList();

    if (FirebaseBootstrap.enabled) {
      unawaited(
        _appointmentRepo.mergeStatus(
          appointmentId: appointmentId,
          status: AppointmentStatus.completed,
        ),
      );
    }

    _addNotification(
      AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Rate Your Visit',
        message: 'Your appointment is completed. Share your feedback.',
        type: NotificationType.appointment,
        timeLabel: 'Just now',
      ),
    );

    notifyListeners();
  }

  void tickQueue() {
    final snapshot = queueSnapshot;
    if (snapshot == null || snapshot.patientsAhead <= 0) {
      return;
    }

    final updatedPatientsAhead = snapshot.patientsAhead - 1;
    final updatedWait = max(3, snapshot.estimatedWaitMinutes - 6);

    queueSnapshot = snapshot.copyWith(
      currentToken: snapshot.currentToken + 1,
      patientsAhead: updatedPatientsAhead,
      estimatedWaitMinutes: updatedWait,
    );

    if (FirebaseBootstrap.enabled && queueSnapshot != null) {
      unawaited(_queueRepo.upsert(queueSnapshot!));
    }

    if (updatedPatientsAhead == 2) {
      _addNotification(
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Queue Update',
          message: 'Only 2 patients are ahead of you now.',
          type: NotificationType.queue,
          timeLabel: 'Now',
        ),
      );
    }

    if (updatedPatientsAhead == 0) {
      _addNotification(
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Please Arrive At Clinic',
          message: 'Your token is next. Please reach the clinic now.',
          type: NotificationType.queue,
          timeLabel: 'Now',
        ),
      );
    }

    notifyListeners();
  }

  void toggleReminder(String reminderId) {
    reminders = reminders.map((item) {
      if (item.id != reminderId) return item;
      return item.copyWith(isEnabled: !item.isEnabled);
    }).toList();

    final updated = reminders.where((r) => r.id == reminderId);
    if (updated.isNotEmpty) {
      final reminder = updated.first;
      // Persist toggle to Firebase.
      if (FirebaseBootstrap.enabled) {
        unawaited(_reminderRepo.upsert(reminder));
      }
      // Schedule or cancel device alarm based on new state.
      if (reminder.isEnabled) {
        unawaited(NotificationService.instance.scheduleReminder(reminder));
      } else {
        unawaited(NotificationService.instance.cancelReminder(reminder.id));
      }
    }

    notifyListeners();
  }

  /// Fetches the full message list from Firebase RTDB and displays it in the UI.
  Future<void> loadAiChatHistory() async {
    final uid = firebaseUserId;
    if (uid == null) return;

    if (!FirebaseBootstrap.enabled) {
      notifyListeners();
      return;
    }

    try {
      final latestRef = FirebaseDatabase.instance.ref('users/$uid/chat_sessions/latest/messages');
      final snapshot = await latestRef.get();

      if (snapshot.exists) {
        final value = snapshot.value;
        List<dynamic> list = <dynamic>[];
        if (value is List) {
          list = value;
        } else if (value is Map) {
          final sortedKeys = value.keys
              .map((k) => int.tryParse(k.toString()) ?? 0)
              .toList()
            ..sort();
          list = sortedKeys.map((k) => value[k.toString()]).toList();
        }

        if (list.isNotEmpty) {
          aiChatHistory = list
              .map((item) {
                if (item is Map) {
                  final map = Map<String, dynamic>.from(item);
                  return ChatMessage(
                    text: map['text'] as String? ?? '',
                    isUser: map['isUser'] as bool? ?? false,
                  );
                }
                return const ChatMessage(text: '', isUser: false);
              })
              .where((m) => m.text.isNotEmpty)
              .toList();
        } else {
          _resetChatHistoryToGreeting();
        }
      } else {
        _resetChatHistoryToGreeting();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      _resetChatHistoryToGreeting();
    }
    notifyListeners();
  }

  /// Starts a fresh chat session, archiving the current latest messages to a timestamped session path.
  Future<void> startNewChatSession() async {
    final uid = firebaseUserId;
    if (uid == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Filter out the greeting message to only persist actual chat history
    final actualMessages = aiChatHistory
        .where((m) => m.text != 'Hello! I\'m your Qurexa AI Health Assistant. Ask me anything about your symptoms or health concerns.')
        .map((m) => {
              'text': m.text,
              'isUser': m.isUser,
            })
        .toList();

    if (FirebaseBootstrap.enabled && actualMessages.isNotEmpty) {
      try {
        // Archive current session under users/{uid}/chat_sessions/{timestamp}
        final archiveRef = FirebaseDatabase.instance.ref('users/$uid/chat_sessions/$timestamp');
        await archiveRef.set({
          'messages': actualMessages,
          'timestamp': timestamp,
        });

        // Clear the latest session in the database
        final latestRef = FirebaseDatabase.instance.ref('users/$uid/chat_sessions/latest');
        await latestRef.remove();
      } catch (e) {
        debugPrint('Error archiving session: $e');
      }
    }

    _resetChatHistoryToGreeting();
    notifyListeners();
  }

  void _resetChatHistoryToGreeting() {
    aiChatHistory = <ChatMessage>[
      const ChatMessage(
        text: 'Hello! I\'m your Qurexa AI Health Assistant. Ask me anything about your symptoms or health concerns.',
        isUser: false,
      ),
    ];
  }

  Stream<String> streamAssistantChat(String userMessage) async* {
    isAiAssistantTyping = true;
    showEmergencyBanner = false;
    notifyListeners();

    final uid = firebaseUserId;

    // 1. Multilingual Local Safety Keyword & Regex Check
    if (EmergencyParser.isEmergency(userMessage)) {
      isAiAssistantTyping = false;
      showEmergencyBanner = true;

      const warningText =
          '⚠️ CRITICAL EMERGENCY DETECTED: Your symptoms suggest a potential '
          'acute medical emergency. Bypassing AI analysis. Please immediately '
          'dial 1122 or 15 or proceed to the nearest emergency room.';

      aiChatHistory = <ChatMessage>[
        ...aiChatHistory,
        ChatMessage(text: userMessage, isUser: true),
        const ChatMessage(text: warningText, isUser: false),
      ];
      notifyListeners();

      if (uid != null && FirebaseBootstrap.enabled) {
        try {
          final messagesRef = FirebaseDatabase.instance.ref('users/$uid/chat_sessions/latest/messages');
          final actualMessages = aiChatHistory
              .where((m) => m.text != 'Hello! I\'m your Qurexa AI Health Assistant. Ask me anything about your symptoms or health concerns.')
              .map((m) => {
                    'text': m.text,
                    'isUser': m.isUser,
                  })
              .toList();
          await messagesRef.set(actualMessages);
        } catch (e) {
          debugPrint('Error saving emergency pair: $e');
        }
      }

      yield warningText;
      return;
    }

    // Append user message locally
    aiChatHistory = <ChatMessage>[
      ...aiChatHistory,
      ChatMessage(text: userMessage, isUser: true),
    ];
    notifyListeners();

    // 2. Prepare conversation history in OpenAI message format.
    //    Use a token-efficient sliding window: only pass the last 6 items as context.
    final rawHistory = aiChatHistory
        .where((m) => m.text != 'Hello! I\'m your Qurexa AI Health Assistant. Ask me anything about your symptoms or health concerns.')
        .toList();

    // Remove the new user message we just added from history context since it is passed explicitly as the last item
    if (rawHistory.isNotEmpty && rawHistory.last.text == userMessage && rawHistory.last.isUser) {
      rawHistory.removeLast();
    }

    final windowedHistory = rawHistory.length > 6
        ? rawHistory.sublist(rawHistory.length - 6)
        : rawHistory;

    final messages = <Map<String, String>>[
      // Inject patient bio context if available
      if (profileCompleted && profile != null)
        <String, String>{
          'role': 'user',
          'content':
              '[Context] The current patient is a ${profile!.age}-year-old '
              '${profile!.gender}. Keep this in mind for all replies.',
        },
      // Map windowed chat history to OpenAI role format
      ...windowedHistory.map((m) => <String, String>{
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          }),
      // Append the new user message
      <String, String>{'role': 'user', 'content': userMessage},
    ];

    // 3. Stream response from Groq (token-by-token SSE)
    final stream = _aiService.streamChat(messages);
    final fullResponseBuffer = StringBuffer();

    await for (final delta in stream) {
      fullResponseBuffer.write(delta);
      // Yield cumulative text so the UI can render progressively
      yield fullResponseBuffer.toString();
    }

    isAiAssistantTyping = false;

    // 4. Persist the complete AI response
    final fullResponse = fullResponseBuffer.toString();
    if (fullResponse.isNotEmpty) {
      aiChatHistory = <ChatMessage>[
        ...aiChatHistory,
        ChatMessage(text: fullResponse, isUser: false),
      ];
      notifyListeners();

      if (uid != null && FirebaseBootstrap.enabled) {
        try {
          final messagesRef = FirebaseDatabase.instance.ref('users/$uid/chat_sessions/latest/messages');
          final actualMessages = aiChatHistory
              .where((m) => m.text != 'Hello! I\'m your Qurexa AI Health Assistant. Ask me anything about your symptoms or health concerns.')
              .map((m) => {
                    'text': m.text,
                    'isUser': m.isUser,
                  })
              .toList();
          await messagesRef.set(actualMessages);
        } catch (e) {
          debugPrint('Error saving chat session: $e');
        }
      }
    } else {
      notifyListeners();
    }
  }

  Future<void> runSymptomChecker(String symptomText) async {
    isSymptomCheckerLoading = true;
    symptomCheckerError = null;
    notifyListeners();

    // 1. Multilingual Local Safety Keyword & Regex Check
    if (EmergencyParser.isEmergency(symptomText)) {
      triageSummary = "Urgent clinical attention required: Safety parser intercepted high-risk emergency markers.";
      triageUrgency = "EMERGENCY";
      triageRationalization = "Your reported symptoms match indicators of an acute medical emergency. Bypassing AI to ensure zero delay of clinical care.";
      triageSpecialties = <String>["Emergency Medicine", "Cardiologist", "Pulmonologist"];
      triageFollowUps = <String>["Immediately dial emergency numbers or proceed to the nearest hospital."];
      triageConditions = <String>["Acute Emergency Condition"];
      latestAiSuggestions = triageSpecialties;
      isSymptomCheckerLoading = false;
      notifyListeners();
      return;
    }

    try {
      final rawResponse = await _aiService.runSymptomTriage(symptomText);
      
      // 2. Resilient JSON extraction via regex matching offloaded to background isolate
      final parsed = await compute(parseTriageResponseIsolate, rawResponse);
      
      triageSummary = parsed['summary'] as String? ?? 'Symptoms cataloged successfully.';
      triageUrgency = (parsed['urgency'] as String? ?? 'NON_URGENT').toUpperCase();
      triageRationalization = parsed['rationalization'] as String? ?? '';
      
      triageSpecialties = List<String>.from(parsed['suggested_specialties'] as List? ?? <String>[]);
      triageFollowUps = List<String>.from(parsed['follow_up_questions'] as List? ?? <String>[]);
      triageConditions = List<String>.from(parsed['cautious_conditions'] as List? ?? <String>[]);

      latestAiSuggestions = triageSpecialties.isNotEmpty ? triageSpecialties : <String>['General Physician'];
    } catch (e) {
      symptomCheckerError = "Clinical Triage Suspended: $e";
      triageSummary = "We encountered a temporary processing issue cataloging your symptoms.";
      triageUrgency = "URGENT";
      triageRationalization = "Please consult a medical practitioner directly to evaluate your symptoms safely.";
      triageSpecialties = <String>["General Physician"];
      triageFollowUps = <String>["Please share your symptoms in detail with your doctor."];
      triageConditions = <String>["Triage Assessment Incomplete"];
      latestAiSuggestions = triageSpecialties;
    } finally {
      isSymptomCheckerLoading = false;
      notifyListeners();
    }
  }

  Future<Prescription> getPrescriptionForRecord(HealthRecord record) async {
    // Try to fetch the doctor-authored full prescription from Firebase first.
    if (FirebaseBootstrap.enabled) {
      final uid = firebaseUserId;
      if (uid != null) {
        final real = await _prescriptionRepo.getForRecord(record, uid);
        if (real != null) return real;
      }
    }
    // Fallback: reconstruct from the HealthRecord's real data stored in Firebase.
    // This contains the actual doctor name and issue — no mock values.
    return _buildPrescriptionFromRecord(record);
  }

  /// Reconstructs a Prescription from a HealthRecord when no dedicated
  /// prescription document exists (e.g. older records or connectivity issues).
  Prescription _buildPrescriptionFromRecord(HealthRecord record) {
    // Parse out individual medicines from the comma-separated prescription summary.
    final List<PrescriptionMedicine> parsedMedicines = record.prescriptionSummary
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((name) => PrescriptionMedicine(
              name: name,
              dose: '',
              frequency: 'As directed',
              duration: 'As directed',
            ))
        .toList();

    return Prescription(
      id: 'rx_${record.id}',
      date: record.date,
      doctorName: record.doctorName,
      patientName: profile?.fullName ?? 'Patient',
      diagnosis: record.diagnosisNotes,
      medicines: parsedMedicines.isNotEmpty
          ? parsedMedicines
          : const <PrescriptionMedicine>[
              PrescriptionMedicine(
                name: 'See prescription notes',
                dose: '',
                frequency: '',
                duration: '',
              ),
            ],
      notes: record.prescriptionSummary,
    );
  }

  void sendDoctorPrescription({
    required PatientCase patientCase,
    required List<PrescriptionMedicine> medicines,
    required String notes,
  }) {
    // Use the logged-in doctor's name from their profile, with a safe fallback.
    final doctorName = profile?.fullName ?? 'Doctor';
    final doctorUid = _auth.currentUser?.uid;
    final patientUid = patientCase.patientUid;
    final now = DateTime.now().millisecondsSinceEpoch;
    final caseId = patientCase.id;

    final summary = medicines
        .map((medicine) => '${medicine.name} ${medicine.dose}')
        .join(', ');

    final newRecord = HealthRecord(
      id: 'r_$caseId',
      date: DateTime.now(),
      doctorName: doctorName,
      issue: patientCase.symptoms,
      diagnosisNotes: notes,
      prescriptionSummary: summary,
    );

    records = <HealthRecord>[newRecord, ...records];

    // Build new reminders list.
    final newReminders = medicines
        .map(
          (medicine) => MedicationReminder(
            id: 'm_${caseId}_${medicine.name}',
            medicineName: '${medicine.name} ${medicine.dose}',
            times: const <String>['9:00 AM', '3:00 PM', '9:00 PM'],
            remainingDays: 5,
            isEnabled: true,
          ),
        )
        .toList();

    reminders = <MedicationReminder>[...newReminders, ...reminders];

    if (FirebaseBootstrap.enabled && doctorUid != null && patientUid != null) {
      // Build the full Prescription object for storage.
      final fullPrescription = Prescription(
        id: 'rx_$caseId',
        date: DateTime.now(),
        doctorName: doctorName,
        patientName: patientCase.patientName,
        diagnosis: notes,
        medicines: medicines,
        notes: notes,
      );

      // Build AppNotification for the patient to notify them.
      final patientNotification = AppNotification(
        id: 'n_rx_$caseId',
        title: 'Prescription Ready',
        message: 'Dr. $doctorName has sent your prescription and set medication reminders.',
        type: NotificationType.medication,
        timeLabel: 'Now',
      );

      // Build atomic multi-path update:
      // 1. Write health record to /patient_records/<patientUid>/<recordId>
      // 2. Write full prescription to /patient_prescriptions/<patientUid>/<prescriptionId>
      // 3. Write each reminder to /patient_reminders/<patientUid>/<reminderId>
      // 4. Remove the patient case from /doctors/<doctorUid>/queue/<caseId>
      // 5. Remove the patient's queue snapshot from /patient_queue_snapshots/<patientUid>
      // 6. Update appointment status to 'completed'
      // 7. Write AppNotification to /users/<patientUid>/notifications/<notificationId>
      final Map<String, dynamic> atomicUpdate = <String, dynamic>{
        '${FirebasePaths.records(patientUid)}/${newRecord.id}':
            HealthRecordRtdbCodec.encode(newRecord),
        '${FirebasePaths.patientPrescriptions(patientUid)}/${fullPrescription.id}':
            PrescriptionRtdbCodec.encode(fullPrescription),
        '${FirebasePaths.notifications(patientUid)}/${patientNotification.id}':
            AppNotificationRtdbCodec.encode(patientNotification),
      };

      for (final reminder in newReminders) {
        atomicUpdate['${FirebasePaths.reminders(patientUid)}/${reminder.id}'] =
            MedicationReminderRtdbCodec.encode(reminder);
      }

      // Remove the patient from the doctor's active queue.
      atomicUpdate['${FirebasePaths.doctorQueue(doctorUid)}/$caseId'] = null;

      // Clear the patient's queue snapshot.
      atomicUpdate[FirebasePaths.queueSnapshot(patientUid)] = null;

      // Update appointment status to completed.
      atomicUpdate[
        '${FirebasePaths.appointments(patientUid)}/$caseId/status'
      ] = AppointmentStatus.completed.name;
      atomicUpdate[
        '${FirebasePaths.appointments(patientUid)}/$caseId/updatedAtMillis'
      ] = now;

      unawaited(_db.ref().update(atomicUpdate));
    }

    // Schedule device alarms for all new reminders.
    for (final reminder in newReminders) {
      unawaited(NotificationService.instance.scheduleReminder(reminder));
    }

    _addNotification(
      AppNotification(
        id: 'n_$caseId',
        title: 'Prescription Ready',
        message: 'New digital prescription was shared with patient.',
        type: NotificationType.system,
        timeLabel: 'Now',
      ),
    );

    notifyListeners();
  }


  void markAllNotificationsAsRead() {
    notifications = notifications
        .map((item) => item.copyWith(isUnread: false))
        .toList();
    if (FirebaseBootstrap.enabled) {
      unawaited(_notificationRepo.markAllRead(notifications));
    }
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    notifications = notifications
        .where((item) => item.id != notificationId)
        .toList();
    if (FirebaseBootstrap.enabled) {
      unawaited(_notificationRepo.delete(notificationId));
    }
    notifyListeners();
  }

  void insertNotification(AppNotification item) {
    if (notifications.any((n) => n.id == item.id)) return;
    notifications = <AppNotification>[item, ...notifications];
    if (FirebaseBootstrap.enabled) {
      unawaited(_notificationRepo.upsert(item));
    }
    notifyListeners();
  }

  Future<void> updateDoctorSchedule(DoctorSchedule value) async {
    doctorSchedule = value;
    notifyListeners();
    if (FirebaseBootstrap.enabled) {
      await _doctorScheduleRepo.upsert(value);
    }
  }

  Stream<DoctorSchedule> getDoctorScheduleStream(String doctorUid) {
    return _doctorScheduleRepo.listenDoctorSchedule(doctorUid: doctorUid);
  }

  Stream<Map<String, String>> getBookedSlotsStream(String doctorUid, String dateStr) {
    return _doctorScheduleRepo.listenBookedSlots(doctorUid: doctorUid, dateStr: dateStr);
  }

  String _formatTimeOfDay(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $ampm';
  }

  String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopRealtimeListeners();
    super.dispose();
  }

  void _addNotification(AppNotification item) {
    notifications = <AppNotification>[item, ...notifications];
    if (FirebaseBootstrap.enabled) {
      unawaited(_notificationRepo.upsert(item));
    }
    unawaited(
      NotificationService.instance.showNotification(
        id: item.id.hashCode,
        title: item.title,
        body: item.message,
      ),
    );
  }
}

/// Top-level parser function running in a background isolate via `compute()`
/// to extract and decode JSON symptom triage responses safely.
Map<String, dynamic> parseTriageResponseIsolate(String rawResponse) {
  final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(rawResponse);
  if (jsonMatch == null) {
    throw const FormatException("Invalid or malformed response format from triage engine.");
  }
  return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
}
