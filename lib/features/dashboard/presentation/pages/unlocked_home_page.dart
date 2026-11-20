import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../onboarding/domain/entities/earning_scheme.dart';
import '../../../onboarding/presentation/bloc/onboarding_cubit.dart';

class UnlockedHomePage extends StatelessWidget {
  const UnlockedHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingCubit = sl<OnboardingCubit>();
    final authCubit = sl<AuthCubit>();

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      bloc: onboardingCubit,
      builder: (context, state) {
        final plan = EarningScheme.byId(state.selectedPlanId);
        final authState = authCubit.state;
        final uid = authState is AuthAuthenticated ? authState.user.uid : '';

        return Scaffold(
          backgroundColor: AppColors.canvasDark,
          appBar: AppBar(
            title: const Text('Milo Driver Partner'),
            actions: [
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  onboardingCubit.clear();
                  authCubit.signOut();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verified Active Partner Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.incomeStripBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.miloCrimson.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.miloCrimson,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${state.driverName}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'ACTIVE FLEET PARTNER • ${plan.title.toUpperCase()}',
                              style: const TextStyle(
                                color: AppColors.incomeGold,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Assigned EV Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ASSIGNED VEHICLE',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            '94% BATTERY',
                            style: TextStyle(
                              color: AppColors.incomeGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tata Xpres-T EV',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'HR 55 AT 4821 • ${state.hubCity}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _DashMetric(
                              label: 'Active Plan',
                              value: plan.shortTitle,
                            ),
                          ),
                          Expanded(
                            child: _DashMetric(
                              label: 'Plan Terms',
                              value: plan.fixedDeduction,
                            ),
                          ),
                          Expanded(
                            child: _DashMetric(
                              label: 'Est. Daily Net',
                              value:
                              '₹${plan.calculateDailyTakeHome(state.dailyRideEstimate)}',
                              gold: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Start Shift CTA
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Shift Online! Ready to accept Milo EV rides.',
                        ),
                        backgroundColor: AppColors.miloCrimson,
                      ),
                    );
                  },
                  icon: const Icon(Icons.electric_bolt_rounded),
                  label: const Text('Go Online & Start Shift'),
                ),
                const SizedBox(height: 14),

                // Reset Onboarding Demo Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: uid.isEmpty
                      ? null
                      : () => onboardingCubit.resetDemoFlow(uid),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Replay Onboarding Flow (Reset to New Lead)'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;

  const _DashMetric({
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: gold ? AppColors.incomeGold : AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}