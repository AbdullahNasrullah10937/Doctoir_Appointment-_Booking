import 'package:flutter/material.dart';

import '../../domain/entities/app_entities.dart';
import '../../domain/entities/role_mismatch_exception.dart';

/// The two choices a user can make when a role mismatch is detected.
enum _MismatchChoice { goBack, signUp }

/// A non-dismissible dialog shown when a returning user tries to sign in with
/// a role that differs from their permanently stored role.
///
/// Returns a [_MismatchChoice] via [Navigator.pop].
class RoleMismatchDialog extends StatelessWidget {
  const RoleMismatchDialog({super.key, required this.exception});

  final RoleMismatchException exception;

  static String _label(UserRole role) =>
      role == UserRole.doctor ? 'Doctor' : 'Patient';

  @override
  Widget build(BuildContext context) {
    final registeredLabel = _label(exception.registeredRole);
    final selectedLabel = _label(exception.selectedRole);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: <Widget>[
          const Icon(Icons.shield_outlined, color: Color(0xFFE65100), size: 22),
          const SizedBox(width: 8),
          const Text(
            'Role Mismatch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF424242),
                height: 1.5,
              ),
              children: <TextSpan>[
                const TextSpan(text: 'This Google account is registered as a '),
                TextSpan(
                  text: registeredLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ', but you selected '),
                TextSpan(
                  text: selectedLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' on the sign-in page.\n\n'),
                const TextSpan(
                  text:
                      'Role is permanently bound to your account and cannot be changed.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF9800), width: 0.8),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFE65100),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To use a different role, register with a different Google account.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE65100),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: <Widget>[
        // Primary: go back and use correct role
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () =>
                Navigator.of(context).pop(_MismatchChoice.goBack),
            child: Text('Sign in as $registeredLabel'),
          ),
        ),
        const SizedBox(height: 6),
        // Secondary: go to signup with a different account
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF424242),
              side: const BorderSide(color: Color(0xFFBDBDBD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () =>
                Navigator.of(context).pop(_MismatchChoice.signUp),
            child: const Text('Use different account'),
          ),
        ),
      ],
    );
  }
}

/// Shows the [RoleMismatchDialog] and handles both user choices.
///
/// [onGoBack] — called when user wants to sign in with the correct stored role.
/// [onSignUp] — called when user wants to register a new account.
Future<void> showRoleMismatchDialog({
  required BuildContext context,
  required RoleMismatchException exception,
  required VoidCallback onGoBack,
  required VoidCallback onSignUp,
}) async {
  final choice = await showDialog<_MismatchChoice>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RoleMismatchDialog(exception: exception),
  );

  if (choice == _MismatchChoice.goBack) {
    onGoBack();
  } else if (choice == _MismatchChoice.signUp) {
    onSignUp();
  }
}
