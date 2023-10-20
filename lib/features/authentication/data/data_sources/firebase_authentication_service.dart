import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class FireBaseAuthenticationService {
  /// Tries to sign in a user with the given [email] and [password]
  /// and returns a [UserCredential] if successful.
  ///
  /// Throws a [FirebaseAuthException] if the sign in fails.
  Future<UserCredential> signedInWithEmailAndPassword(
    String email,
    String password,
  );

  /// Signs out the current user.
  Future<void> signOut();
}

@Singleton(as: FireBaseAuthenticationService)
class FireBaseAuthenticationServiceImpl
    implements FireBaseAuthenticationService {
  final FirebaseAuth _firebaseAuth;

  FireBaseAuthenticationServiceImpl(this._firebaseAuth);

  @override
  Future<UserCredential> signedInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw FirebaseAuthException(
          code: 'ERROR_USER_NOT_FOUND',
          message: 'No user found for that email.',
        );
      } else {
        return result;
      }
    } on FirebaseException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message!,
      );
    }
  }

  @override
  Future<void> signOut() {
    try {
      return _firebaseAuth.signOut();
    } on FirebaseException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message!,
      );
    }
  }
}
