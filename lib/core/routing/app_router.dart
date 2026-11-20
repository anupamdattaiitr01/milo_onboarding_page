import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/dashboard/presentation/pages/unlocked_home_page.dart';
import '../../features/onboarding/presentation/bloc/onboarding_cubit.dart';
import '../../features/onboarding/presentation/pages/onboarding_plans_page.dart';
import '../../features/onboarding/presentation/pages/pending_approval_page.dart';
import '../di/injection_container.dart';

class AppRouter {
  static final _authCubit = sl<AuthCubit>();
  static final _onboardingCubit = sl<OnboardingCubit>();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _MultiStreamRefreshListenable([
      _authCubit.stream,
      _onboardingCubit.stream,
    ]),
    redirect: (context, state) {
      final authState = _authCubit.state;
      final loc = state.matchedLocation;

      // 1. User is authenticated via Firebase Phone Auth
      if (authState is AuthAuthenticated) {
        // Ensure Realtime Database listener is bound to drivers/{uid}
        _onboardingCubit.bindDriver(
          authState.user.uid,
          authState.user.phoneNumber ?? '+919876543210',
        );

        final status = _onboardingCubit.state.authzStatus;

        // Route strictly by Firebase Realtime Database `status`
        switch (status) {
          case AuthorizationStatus.active:
            return loc == '/home' ? null : '/home';

          case AuthorizationStatus.planSelected:
            return loc == '/onboarding/pending' ? null : '/onboarding/pending';

          case AuthorizationStatus.newLead:
          case AuthorizationStatus.unknown:
            return loc == '/onboarding/plans' ? null : '/onboarding/plans';
        }
      }

      // 2. OTP sent or awaiting retry -> keep user on /otp
      final isOnOtpFlow = authState is AuthOtpSent ||
          authState is AuthVerifyingOtp ||
          (authState is AuthFailure && authState.verificationId != null);

      if (isOnOtpFlow) {
        return loc == '/otp' ? null : '/otp';
      }

      // 3. Unauthenticated -> keep user on /login
      return loc == '/login' ? null : '/login';
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, _) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: '/onboarding/plans',
        builder: (_, _) => const OnboardingPlansPage(),
      ),
      GoRoute(
        path: '/onboarding/pending',
        builder: (_, _) => const PendingApprovalPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const UnlockedHomePage(),
      ),
    ],
  );
}

class _MultiStreamRefreshListenable extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  _MultiStreamRefreshListenable(List<Stream<dynamic>> streams) {
    _subscriptions = streams
        .map((stream) => stream.listen((_) => notifyListeners()))
        .toList();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}