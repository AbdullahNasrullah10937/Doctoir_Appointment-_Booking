import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/security/emergency_parser.dart';
import '../../core/services/groq_service.dart';
import '../../data/firebase/patient_cloud_sync.dart';
import '../../data/repositories/mock_app_repository.dart';
import '../../domain/entities/app_entities.dart';
import '../../domain/entities/role_mismatch_exception.dart';
import '../../domain/repositories/app_repository.dart';
import '../widgets/screen_helpers.dart';

class AppState extends ChangeNotifier {
  AppState({AppRepository? repository})
    : _repository = repository ?? MockAppRepository();

  final AppRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  StreamSubscription<List<Doctor>>? _doctorCatalogSub;
  StreamSubscription<List<Appointment>>? _appointmentsSub;
  StreamSubscription<List<HealthRecord>>? _recordsSub;
  StreamSubscription<List<MedicationReminder>>? _remindersSub;
  StreamSubscription<List<AppNotification>>? _notificationsSub;
  StreamSubscription<QueueSnapshot?>? _queueSnapshotSub;
  StreamSubscription<List<PatientCase>>? _doctorQueueSub;
  StreamSubscription<DoctorSchedule?>? _doctorScheduleSub;

  final GroqService _groqService = GroqService();

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

    doctors = await _repository.getDoctors();
    appointments = await _repository.getAppointments();
    records = await _repository.getHealthRecords();
    reminders = await _repository.getMedicationReminders();
    notifications = await _repository.getNotifications();
    doctorQueue = await _repository.getDoctorQueue();
    doctorSchedule = await _repository.getDoctorSchedule();
    queueSnapshot = await _repository.getQueueSnapshot();

    await _restoreFirebaseSession();

    initialized = true;
    isBootstrapping = false;
    notifyListeners();
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
        final storedRole = restored.restoredRole;
        if (roleOverride != null && roleOverride != storedRole) {
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
            if (roleOverride != null && roleOverride != fallbackRole) {
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
    profileCompleted = role == UserRole.doctor || profile != null;

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
      if (items.isNotEmpty) {
        doctors = items;
        notifyListeners();
      }
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

    _notificationsSub = _notificationRepo
        .listenNotifications(firebaseUid: uid)
        .listen((items) {
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
    _doctorCatalogSub = null;
    _appointmentsSub = null;
    _recordsSub = null;
    _remindersSub = null;
    _notificationsSub = null;
    _queueSnapshotSub = null;
    _doctorQueueSub = null;
    _doctorScheduleSub = null;
    
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

  Appointment bookAppointment({required AppointmentDraft draft}) {
    final token = 12 + Random().nextInt(10);

    final appointment = Appointment(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      doctor: draft.doctor,
      dateTime: draft.slotDateTime,
      tokenNumber: token,
      status: AppointmentStatus.upcoming,
      visitReason: draft.visitReason,
      isVideoConsultation: draft.isVideoConsultation,
    );

    appointments = <Appointment>[appointment, ...appointments];

    queueSnapshot = QueueSnapshot(
      doctorName: draft.doctor.name,
      clinicLocation: draft.doctor.hospital,
      yourToken: token,
      currentToken: token - 4,
      patientsAhead: 4,
      estimatedWaitMinutes: 25,
    );

    if (FirebaseBootstrap.enabled && queueSnapshot != null) {
      unawaited(_appointmentRepo.upsert(appointment));
      unawaited(_queueRepo.upsert(queueSnapshot!));
    }

    _addNotification(
      AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
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
      if (item.id != reminderId) {
        return item;
      }

      return item.copyWith(isEnabled: !item.isEnabled);
    }).toList();

    if (FirebaseBootstrap.enabled) {
      final updated = reminders.where((item) => item.id == reminderId);
      if (updated.isNotEmpty) {
        unawaited(_reminderRepo.upsert(updated.first));
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
    final stream = _groqService.streamChatResponse(messages);
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
      final rawResponse = await _groqService.runSymptomTriage(symptomText);
      
      // 2. Resilient JSON extraction via regex matching (isolates JSON from any wrapping markdown text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(rawResponse);
      if (jsonMatch == null) {
        throw const FormatException("Invalid or malformed response format from triage engine.");
      }

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      
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

  Future<Prescription> getPrescriptionForRecord(HealthRecord record) {
    return _repository.getPrescriptionForRecord(record);
  }

  void sendDoctorPrescription({
    required PatientCase patientCase,
    required List<PrescriptionMedicine> medicines,
    required String notes,
  }) {
    // Use the logged-in doctor's name from their profile, with a safe fallback.
    final doctorName = profile?.fullName ?? 'Doctor';

    final summary = medicines
        .map((medicine) => '${medicine.name} ${medicine.dose}')
        .join(', ');

    final newRecord = HealthRecord(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      doctorName: doctorName, // fixed: was always hardcoded 'Dr. Sara Ali'
      issue: patientCase.symptoms,
      diagnosisNotes: notes,
      prescriptionSummary: summary,
    );

    records = <HealthRecord>[newRecord, ...records];

    // Build new reminders list — keep a reference to the new ones for upsert.
    final newReminders = medicines
        .map(
          (medicine) => MedicationReminder(
            id: 'm_${DateTime.now().millisecondsSinceEpoch}_${medicine.name}',
            medicineName: '${medicine.name} ${medicine.dose}',
            times: const <String>['9:00 AM', '3:00 PM', '9:00 PM'],
            remainingDays: 5,
            isEnabled: true,
          ),
        )
        .toList();

    reminders = <MedicationReminder>[...newReminders, ...reminders];

    // Sync to Firebase only when properly initialised.
    if (FirebaseBootstrap.enabled) {
      unawaited(_recordRepo.upsert(newRecord));
      for (final reminder in newReminders) {
        unawaited(_reminderRepo.upsert(reminder));
      }
    }

    _addNotification(
      AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Prescription Ready',
        message: 'New digital prescription was shared with patient.',
        type: NotificationType.system,
        timeLabel: 'Now',
      ),
    );

    notifyListeners();
  }

  void updateDoctorSchedule(DoctorSchedule value) {
    doctorSchedule = value;
    if (FirebaseBootstrap.enabled) {
      unawaited(_doctorScheduleRepo.upsert(value));
    }
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
  }
}
