import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthSendingOtp extends AuthState {
  const AuthSendingOtp();
}

class AuthOtpSent extends AuthState {
  final String phoneNumber;
  final String verificationId;

  const AuthOtpSent({
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  List<Object?> get props => [phoneNumber, verificationId];
}

class AuthVerifyingOtp extends AuthState {
  final String phoneNumber;
  final String verificationId;

  const AuthVerifyingOtp({
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  List<Object?> get props => [phoneNumber, verificationId];
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.uid];
}

class AuthFailure extends AuthState {
  final String message;
  final String? phoneNumber;
  final String? verificationId;

  const AuthFailure(
      this.message, {
        this.phoneNumber,
        this.verificationId,
      });

  @override
  List<Object?> get props => [message, phoneNumber, verificationId];
}

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _firebaseAuth;
  StreamSubscription<User?>? _authSub;

  int? _resendToken;
  String? _lastPhoneNumber;
  String? _lastVerificationId;

  AuthCubit(this._firebaseAuth) : super(const AuthInitial()) {
    _authSub = _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else if (state is AuthAuthenticated) {
        emit(const AuthInitial());
      }
    });
  }

  String? get lastPhoneNumber => _lastPhoneNumber;
  String? get lastVerificationId => _lastVerificationId;

  Future<void> sendOtp(String tenDigitNumber, {bool isResend = false}) async {
    final formattedPhone = '+91${tenDigitNumber.replaceAll(RegExp(r'\D'), '')}';
    _lastPhoneNumber = formattedPhone;
    emit(const AuthSendingOtp());

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _firebaseAuth.signInWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            emit(AuthFailure(
              e.message ?? 'Auto-verification failed.',
              phoneNumber: _lastPhoneNumber,
              verificationId: _lastVerificationId,
            ));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          emit(AuthFailure(
            _mapFirebaseError(e),
            phoneNumber: _lastPhoneNumber,
            verificationId: _lastVerificationId,
          ));
        },
        codeSent: (String verificationId, int? resendToken) {
          _lastVerificationId = verificationId;
          _resendToken = resendToken;
          emit(AuthOtpSent(
            phoneNumber: formattedPhone,
            verificationId: verificationId,
          ));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _lastVerificationId = verificationId;
        },
      );
    } catch (e) {
      emit(AuthFailure('Unable to send OTP. Check your network connection.'));
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    final verId = _lastVerificationId;
    final phone = _lastPhoneNumber ?? '';

    if (verId == null || verId.isEmpty) {
      emit(const AuthFailure('Session expired. Please request a new OTP.'));
      return;
    }

    emit(AuthVerifyingOtp(phoneNumber: phone, verificationId: verId));

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verId,
        smsCode: smsCode.trim(),
      );
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(
        _mapFirebaseError(e),
        phoneNumber: phone,
        verificationId: verId,
      ));
    } catch (_) {
      emit(AuthFailure(
        'Invalid OTP. Please try again.',
        phoneNumber: phone,
        verificationId: verId,
      ));
    }
  }

  void resetToPhoneInput() {
    _lastVerificationId = null;
    emit(const AuthInitial());
  }

  Future<void> signOut() async {
    _lastPhoneNumber = null;
    _lastVerificationId = null;
    _resendToken = null;
    await _firebaseAuth.signOut();
    emit(const AuthInitial());
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Enter a valid 10-digit Indian mobile number.';
      case 'invalid-verification-code':
        return 'Incorrect 6-digit OTP. Please check and try again.';
      case 'session-expired':
        return 'OTP expired. Tap Resend OTP to get a new code.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}