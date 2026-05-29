import 'package:flutter/material.dart';

import '../../domain/entities/app_entities.dart';
import '../screens/screens.dart';

class AppRouter {
  const AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String profileSetup = '/auth/profile-setup';

  static const String patientShell = '/patient/shell';
  static const String doctorSearch = '/patient/search';
  static const String doctorProfile = '/patient/doctor-profile';
  static const String bookAppointment = '/patient/book-appointment';
  static const String payment = '/patient/payment';
  static const String queueTracker = '/patient/queue';
  static const String aiSymptomChecker = '/patient/ai-checker';
  static const String aiAssistant = '/patient/ai-assistant';
  static const String digitalPrescription = '/patient/prescription';
  static const String medicationReminders = '/patient/reminders';
  static const String notifications = '/patient/notifications';
  static const String helpSupport = '/patient/help-support';
  static const String emergency = '/patient/emergency';
  static const String rateReview = '/patient/rate-review';
  static const String videoConsultation = '/patient/video';

  static const String doctorShell = '/doctor/shell';
  static const String doctorPatientDetails = '/doctor/patient-details';
  static const String doctorWritePrescription = '/doctor/write-prescription';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
        );
      case login:
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute<void>(builder: (_) => const SignupScreen());

      case profileSetup:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileSetupScreen(),
        );
      case patientShell:
        return MaterialPageRoute<void>(
          builder: (_) => const PatientShellScreen(),
        );
      case doctorSearch:
        final initialSpecialty = settings.arguments is String
            ? settings.arguments! as String
            : null;
        return MaterialPageRoute<void>(
          builder: (_) =>
              DoctorSearchScreen(initialSpecialty: initialSpecialty),
        );
      case doctorProfile:
        return MaterialPageRoute<void>(
          builder: (_) =>
              DoctorProfileScreen(doctor: settings.arguments! as Doctor),
        );
      case bookAppointment:
        return MaterialPageRoute<void>(
          builder: (_) =>
              BookAppointmentScreen(doctor: settings.arguments! as Doctor),
        );
      case payment:
        return MaterialPageRoute<void>(
          builder: (_) =>
              PaymentScreen(draft: settings.arguments! as AppointmentDraft),
        );
      case queueTracker:
        return MaterialPageRoute<void>(
          builder: (_) => QueueTrackerScreen(
            appointment: settings.arguments! as Appointment,
          ),
        );
      case aiSymptomChecker:
        return MaterialPageRoute<void>(
          builder: (_) => const AiSymptomCheckerScreen(),
        );
      case aiAssistant:
        return MaterialPageRoute<void>(
          builder: (_) => const AiHealthAssistantScreen(),
        );
      case digitalPrescription:
        final record = settings.arguments is HealthRecord
            ? settings.arguments! as HealthRecord
            : null;
        return MaterialPageRoute<void>(
          builder: (_) => DigitalPrescriptionScreen(record: record),
        );
      case medicationReminders:
        return MaterialPageRoute<void>(
          builder: (_) => const MedicationRemindersScreen(),
        );
      case notifications:
        return MaterialPageRoute<void>(
          builder: (_) => const NotificationsScreen(),
        );
      case helpSupport:
        return MaterialPageRoute<void>(
          builder: (_) => const HelpSupportScreen(),
        );
      case emergency:
        return MaterialPageRoute<void>(
          builder: (_) => const EmergencyNumbersScreen(),
        );
      case rateReview:
        final doctor = settings.arguments is Doctor
            ? settings.arguments! as Doctor
            : null;
        return MaterialPageRoute<void>(
          builder: (_) => RateReviewScreen(doctor: doctor),
        );
      case videoConsultation:
        final doctor = settings.arguments is Doctor
            ? settings.arguments! as Doctor
            : null;
        return MaterialPageRoute<void>(
          builder: (_) => VideoConsultationScreen(doctor: doctor),
        );
      case doctorShell:
        return MaterialPageRoute<void>(
          builder: (_) => const DoctorShellScreen(),
        );
      case doctorPatientDetails:
        return MaterialPageRoute<void>(
          builder: (_) => DoctorPatientDetailsScreen(
            patientCase: settings.arguments! as PatientCase,
          ),
        );
      case doctorWritePrescription:
        return MaterialPageRoute<void>(
          builder: (_) => DoctorWritePrescriptionScreen(
            patientCase: settings.arguments! as PatientCase,
          ),
        );
      default:
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
    }
  }
}
