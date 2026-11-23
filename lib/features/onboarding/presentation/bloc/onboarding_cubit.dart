import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthorizationStatus {
  unknown,
  newLead,
  planSelected,
  active,
}

class OnboardingState extends Equatable {
  final AuthorizationStatus authzStatus;
  final String? selectedPlanId;
  final double dailyRideEstimate;
  final bool isTableView;
  final String driverName;
  final String hubCity;
  final bool isSubmitting;
  final String? errorMessage;

  const OnboardingState({
    this.authzStatus = AuthorizationStatus.unknown,
    this.selectedPlanId,
    this.dailyRideEstimate = 3000,
    this.isTableView = false,
    this.driverName = 'Anupam',
    this.hubCity = 'Gurugram / Delhi NCR',
    this.isSubmitting = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    AuthorizationStatus? authzStatus,
    String? selectedPlanId,
    bool clearSelectedPlan = false,
    double? dailyRideEstimate,
    bool? isTableView,
    String? driverName,
    String? hubCity,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnboardingState(
      authzStatus: authzStatus ?? this.authzStatus,
      selectedPlanId:
      clearSelectedPlan ? null : (selectedPlanId ?? this.selectedPlanId),
      dailyRideEstimate: dailyRideEstimate ?? this.dailyRideEstimate,
      isTableView: isTableView ?? this.isTableView,
      driverName: driverName ?? this.driverName,
      hubCity: hubCity ?? this.hubCity,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    authzStatus,
    selectedPlanId,
    dailyRideEstimate,
    isTableView,
    driverName,
    hubCity,
    isSubmitting,
    errorMessage,
  ];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  final FirebaseDatabase _database;
  StreamSubscription<DatabaseEvent>? _driverSub;
  String? _boundUid;

  OnboardingCubit(this._database) : super(const OnboardingState());

  /// Streams `drivers/{uid}` from Firebase Realtime Database for live authorization
  void bindDriver(String uid, String phone) {
    if (_boundUid == uid && _driverSub != null) return;
    _boundUid = uid;
    _driverSub?.cancel();

    final driverRef = _database.ref('drivers/$uid');

    _driverSub = driverRef.onValue.listen(
          (DatabaseEvent event) async {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          await driverRef.set({
            'phone': phone,
            'name': 'Anupam',
            'hub_city': 'Gurugram / Delhi NCR',
            'status': 'new_lead',
            'updated_at': ServerValue.timestamp,
          });
          return;
        }

        final rawValue = event.snapshot.value;
        if (rawValue is! Map) return;

        final data = Map<String, dynamic>.from(rawValue);
        final rawStatus = data['status'] as String? ?? 'new_lead';

        final mappedStatus = switch (rawStatus) {
          'active' => AuthorizationStatus.active,
          'plan_selected' => AuthorizationStatus.planSelected,
          _ => AuthorizationStatus.newLead,
        };

        final remotePlan = data['selected_plan'] as String?;

        emit(state.copyWith(
          authzStatus: mappedStatus,
          selectedPlanId: remotePlan ?? state.selectedPlanId,
          clearSelectedPlan:
          mappedStatus == AuthorizationStatus.newLead && remotePlan == null,
          driverName: (data['name'] as String?) ?? state.driverName,
          hubCity: (data['hub_city'] as String?) ?? state.hubCity,
          isSubmitting: false,
          clearError: true,
        ));
      },
      onError: (Object error) {
        emit(state.copyWith(
          errorMessage: 'Database sync error: $error',
          isSubmitting: false,
        ));
      },
    );
  }

  void selectPlanLocally(String planId) {
    emit(state.copyWith(selectedPlanId: planId, clearError: true));
  }

  void updateDailyEstimate(double value) {
    emit(state.copyWith(dailyRideEstimate: value));
  }

  void toggleTableView(bool isTable) {
    emit(state.copyWith(isTableView: isTable));
  }

  /// Writes the chosen plan to Firebase RTDB and moves status -> `plan_selected`
  Future<bool> submitPlanToHubOps({
    required String uid,
    required String planId,
    required String driverName,
    required String hubCity,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final cleanName =
      driverName.trim().isEmpty ? 'Anupam' : driverName.trim();
      await _database.ref('drivers/$uid').update({
        'name': cleanName,
        'hub_city': hubCity,
        'selected_plan': planId,
        'status': 'plan_selected',
        'updated_at': ServerValue.timestamp,
      });
      emit(state.copyWith(
        selectedPlanId: planId,
        driverName: cleanName,
        hubCity: hubCity,
        isSubmitting: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit plan. Check internet connection.',
      ));
      return false;
    }
  }

  /// Simulates Hub Ops approving the driver
  Future<void> simulateHubOpsApproval(String uid) async {
    await _database.ref('drivers/$uid').update({
      'status': 'active',
      'updated_at': ServerValue.timestamp,
    });
  }

  /// Resets the driver back to `new_lead` so the onboarding flow can be replayed
  Future<void> resetDemoFlow(String uid) async {
    await _database.ref('drivers/$uid').update({
      'status': 'new_lead',
      'selected_plan': null,
      'updated_at': ServerValue.timestamp,
    });
  }

  void clear() {
    _boundUid = null;
    _driverSub?.cancel();
    _driverSub = null;
    emit(const OnboardingState());
  }

  @override
  Future<void> close() {
    _driverSub?.cancel();
    return super.close();
  }
}