part of 'authentication_bloc.dart';

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticationState extends Equatable {
  final AuthenticationStatus status;
  final User? user;
  final String? message;

  const AuthenticationState._({
    this.status = AuthenticationStatus.unknown,
    this.user,
    this.message,
  });

  const AuthenticationState.unknown() : this._();

  const AuthenticationState.authenticated(User user)
      : this._(
          status: AuthenticationStatus.authenticated,
          user: user,
        );

  const AuthenticationState.unauthenticated({String? message})
      : this._(
          status: AuthenticationStatus.unauthenticated,
          message: message,
        );

  @override
  List<Object> get props => [
        status,
        user ?? user == null,
        message ?? message == null,
      ];
}

// final class AuthenticationInitial extends AuthenticationState {
//   @override
//   List<Object> get props => [];
// }

// final class AuthenticationInProgress extends AuthenticationState {
//   @override
//   List<Object> get props => [];
// }

// final class AuthenticatedWithCredential extends AuthenticationState {
//   final User userCredential;

//   const AuthenticatedWithCredential(this.userCredential);

//   @override
//   List<Object> get props => [userCredential];
// }

// final class UnAuthenticated extends AuthenticationState {
//   @override
//   List<Object> get props => [];
// }

// final class AuthenticationFailure extends AuthenticationState {
//   final String message;

//   const AuthenticationFailure(this.message);

//   @override
//   List<Object> get props => [message];
// }
