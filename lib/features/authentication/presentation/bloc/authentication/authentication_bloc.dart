import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/constants/constants.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecase/usecases.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

@injectable
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc(
    this._signInWithEmailAndPasswordUC,
    this._signOutUC,
    this._signInWithGoogleUC,
    this._getCurrentUserUC,
    this._signUpWithEmailUC,
  ) : super(const AuthenticationState.unknown()) {
    on<AuthenticationEventStarted>(_onAuthenticationStarted);
    on<AuthenticationEventStatusChanged>(_onAuthenticationStatusChanged);
    on<SignUpWithEmailEvent>(_onSignUpWithEmail);
    on<AuthenticationEventSignIn>(_onSignedInWithEmailAndPassword);
    on<AuthenticationEventSignInWithGoogle>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
  }

  final SignUpWithEmailUC _signUpWithEmailUC;
  final SignInWithEmailAndPasswordUC _signInWithEmailAndPasswordUC;
  final SignInWithGoogleUC _signInWithGoogleUC;
  final SignOutUC _signOutUC;
  final GetCurrentUserUC _getCurrentUserUC;

  void _onSignInWithGoogle(
    AuthenticationEventSignInWithGoogle event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.authenticating());
    final userEntityEither = await _signInWithGoogleUC();
    userEntityEither.fold(
      (failure) => emit(AuthenticationState.unauthenticated(message: failure.message)),
      (userEntity) => emit(AuthenticationState.authenticated(userEntity, message: 'Welcome back ${userEntity.displayName}')),
    );
  }

  void _onSignedInWithEmailAndPassword(
    AuthenticationEventSignIn event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.authenticating());
    final userEntityEither = await _signInWithEmailAndPasswordUC(SignInParams(email: event.email, password: event.password));

    userEntityEither.fold(
      (failure) => emit(AuthenticationState.unauthenticated(message: failure.message)),
      (userEntity) => emit(AuthenticationState.authenticated(userEntity, message: 'Welcome back ${userEntity.displayName}')),
    );
  }

  void _onAuthenticationStarted(
    AuthenticationEventStarted event,
    Emitter<AuthenticationState> emit,
  ) async {
    final user = _getCurrentUserUC();
    if (user != null) {
      emit(AuthenticationState.authenticated(user));
    } else {
      emit(
        const AuthenticationState.unauthenticated(message: kUserNotLogin),
      );
    }
  }

  void _onSignOut(
    SignOutEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.authenticating());
    try {
      await _signOutUC();
      emit(const AuthenticationState.unauthenticated(message: 'Sign out success'));
    } catch (e) {
      emit(const AuthenticationState.unauthenticated(message: 'Sign out failed'));
    }
  }

  void _onAuthenticationStatusChanged(
    AuthenticationEventStatusChanged event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(const AuthenticationState.authenticating());
    if (event.status == AuthenticationStatus.authenticated) {
      emit(AuthenticationState.authenticated(event.user!));
    } else {
      emit(const AuthenticationState.unauthenticated(message: kUserNotLogin));
    }
  }

  void _onSignUpWithEmail(
    SignUpWithEmailEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.authenticating());
    final result = await _signUpWithEmailUC(
      SignUpParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthenticationState.unauthenticated(message: failure.message)),
      (userEntity) => emit(AuthenticationState.authenticated(userEntity)),
    );
  }
}
