import 'app_entities.dart';

/// Thrown when a returning user attempts to sign in with a role that does not
/// match the role permanently stored in their Firebase account.
///
/// This is a hard authentication failure — the stored role is the single source
/// of truth and can never be overridden after initial registration.
class RoleMismatchException implements Exception {
  const RoleMismatchException({
    required this.selectedRole,
    required this.registeredRole,
  });

  /// The role the user selected on the sign-in page.
  final UserRole selectedRole;

  /// The role that is permanently stored in Firebase for this account.
  final UserRole registeredRole;

  @override
  String toString() {
    final selected = _label(selectedRole);
    final registered = _label(registeredRole);
    return 'Role mismatch: this account is registered as $registered, '
        'but you selected $selected.';
  }

  static String _label(UserRole role) =>
      role == UserRole.doctor ? 'Doctor' : 'Patient';
}
