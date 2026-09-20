import 'package:cloud_functions/cloud_functions.dart';

class AccountDeletionService {
  final FirebaseFunctions _functions;

  AccountDeletionService({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  Future<AccountDeletionCheckResult> requestAccountDeletion() async {
    try {
      final callable = _functions.httpsCallable('deleteAccount');

      final result = await callable.call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      return AccountDeletionCheckResult(
        allowed: data['allowed'] == true,
        message: (data['message'] ?? '').toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw AccountDeletionException(
        code: e.code,
        message: e.message ?? 'Die Accountlöschung konnte nicht geprüft werden.',
      );
    }
  }
}

class AccountDeletionCheckResult {
  final bool allowed;
  final String message;

  const AccountDeletionCheckResult({
    required this.allowed,
    required this.message,
  });
}

class AccountDeletionException implements Exception {
  final String code;
  final String message;

  const AccountDeletionException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}