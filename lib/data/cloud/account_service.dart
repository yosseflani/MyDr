/// The signed-in user of the cloud account.
class Account {
  const Account({required this.uid, required this.email});

  /// Stable id from the authentication service; names the user's folder.
  final String uid;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is Account && other.uid == uid && other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);

  @override
  String toString() => 'Account($uid)';
}

/// Why an account action failed.
enum AccountError {
  invalidEmail,

  /// Wrong email or password (the service does not say which).
  wrongCredentials,
  emailInUse,
  weakPassword,
  network,
  tooManyAttempts,
  unknown,
}

class AccountException implements Exception {
  const AccountException(this.error);

  final AccountError error;

  @override
  String toString() => 'AccountException(${error.name})';
}

/// Signing in to the cloud account that holds the backups. Every method
/// may throw an [AccountException].
abstract interface class AccountService {
  /// The signed-in account, or null.
  Account? get current;

  /// Emits whenever the signed-in account changes.
  Stream<Account?> changes();

  Future<Account> signIn({required String email, required String password});

  Future<Account> register({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
