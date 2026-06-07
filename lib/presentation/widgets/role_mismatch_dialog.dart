import 'package:flutter/material.dart';

import '../../domain/entities/role_mismatch_exception.dart';

/// The two choices a user can make when a role mismatch is detected.
enum _MismatchChoice { goBack, signUp }

/// A non-dismissible dialog shown when a returning user tries to sign in with
/// an incorrect sign-in path or mismatched configuration.
///
/// Returns a [_MismatchChoice] via [Navigator.pop].
class RoleMismatchDialog extends StatelessWidget {
  const RoleMismatchDialog({super.key, required this.exception});

  final RoleMismatchException exception;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: <Widget>[
          Icon(Icons.shield_outlined, color: Color(0xFFE65100), size: 22),
          SizedBox(width: 8),
          Text(
            'Account Exists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'This Google account is already registered with a different configuration.\n\n'
            'To prevent unauthorized access, settings are permanently bound to your account and cannot be modified.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF424242),
              height: 1.5,
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
            child: const Row(
              children: <Widget>[
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFE65100),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please sign in with your original credentials or use a different Google account.',
                    style: TextStyle(
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
        // Primary: go back and sign in
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
            child: const Text('Go to Sign In'),
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
/// [onGoBack] — called when user wants to sign in.
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
