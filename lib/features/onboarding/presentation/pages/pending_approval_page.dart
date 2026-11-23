import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/earning_scheme.dart';
import '../bloc/onboarding_cubit.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  Future<void> _launchExternal(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open external app on this device.'),
          backgroundColor: AppColors.miloCrimson,
        ),
      );
    }
  }

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
          body: SafeArea(
            child: Column(
              children: [
                // Locked Status Header Banner
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.lockBannerBg,
                    border: Border(
                      bottom: BorderSide(color: AppColors.lockBannerBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.lockBannerText,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Verification Pending • Visit Hub to unlock your driver account',
                          style: TextStyle(
                            color: AppColors.lockBannerText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showLogoutConfirmationDialog(
                          context,
                          onConfirmLogout: () {
                            onboardingCubit.clear();
                            authCubit.signOut();
                          },
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Almost Ready, ${state.driverName}!',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your ${plan.title} request is registered for ${state.hubCity}. Complete physical KYC & deposit at the hub to activate your EV.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Selected Plan Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.miloCrimson.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'LOCKED EARNING PLAN',
                                    style: TextStyle(
                                      color: AppColors.incomeGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: uid.isEmpty
                                        ? null
                                        : () =>
                                        onboardingCubit.resetDemoFlow(uid),
                                    child: const Text(
                                      'Change Plan',
                                      style: TextStyle(
                                        color: AppColors.miloCrimsonLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                plan.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _DetailRow(
                                label: 'Security Deposit',
                                value: plan.securityDeposit,
                                highlight: true,
                              ),
                              _DetailRow(
                                label: 'Plan Terms',
                                value: plan.fixedDeduction,
                              ),
                              _DetailRow(
                                label: 'Charging & Maint.',
                                value: plan.chargingAndMaintenance,
                              ),
                              _DetailRow(
                                label: 'Assigned Hub',
                                value: state.hubCity,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Onboarding Checklist Stepper
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Onboarding Status',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 14),
                              _StepTile(
                                title: '1. Mobile Number Verified',
                                subtitle: 'Authenticated via Firebase OTP',
                                isDone: true,
                              ),
                              _StepTile(
                                title: '2. Earning Scheme Selected',
                                subtitle: 'Synced with Milo Hub Ops database',
                                isDone: true,
                              ),
                              _StepTile(
                                title: '3. Hub KYC & Vehicle Handover',
                                subtitle:
                                'Bring Driving License, PAN & Security Deposit to Hub',
                                isDone: false,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Hub Navigation & Call Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(
                                      color: AppColors.borderSubtle),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => _launchExternal(
                                  context,
                                  Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=Milo+Drive+EV+Hub+Gurugram',
                                  ),
                                ),
                                icon: const Icon(Icons.location_on_rounded,
                                    color: AppColors.incomeGold, size: 18),
                                label: const Text('Hub Maps'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(
                                      color: AppColors.borderSubtle),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => _launchExternal(
                                  context,
                                  Uri.parse('tel:+919876543210'),
                                ),
                                icon: const Icon(Icons.call_rounded,
                                    color: AppColors.incomeGold, size: 18),
                                label: const Text('Call Hub'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Live Hub Ops Approval Simulator Button
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.incomeGoldBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.incomeGold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PROTOTYPE HUB OPS DEMO',
                                style: TextStyle(
                                  color: AppColors.incomeGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'In production, Hub Ops flips status to "active" in Firebase after KYC. Tap below to simulate instant approval:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: uid.isEmpty
                                    ? null
                                    : () => onboardingCubit
                                    .simulateHubOpsApproval(uid),
                                icon: const Icon(Icons.verified_rounded,
                                    size: 18),
                                label: const Text(
                                    'Simulate Hub Approval (Unlock App)'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.incomeGold : AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLast;

  const _StepTile({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_checked_rounded,
            color: isDone ? AppColors.incomeGold : AppColors.miloCrimsonLight,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}