import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/onboarding/presentation/bloc/milo_ai_cubit.dart';
import '../../features/onboarding/presentation/bloc/onboarding_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. Firebase SDK Instances
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseDatabase>(() => FirebaseDatabase.instance);

  // 2. Feature Cubits (Singletons so GoRouter and all screens share live state)
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl<FirebaseAuth>()));
  sl.registerLazySingleton<OnboardingCubit>(
        () => OnboardingCubit(sl<FirebaseDatabase>()),
  );
  sl.registerLazySingleton<MiloAiCubit>(() => MiloAiCubit());
}