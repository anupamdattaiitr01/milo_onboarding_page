import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/earning_scheme.dart';
import '../bloc/onboarding_cubit.dart';
import '../widgets/milo_ai_sheet.dart';
import '../widgets/scheme_video_modal.dart';

class OnboardingPlansPage extends StatefulWidget {
  const OnboardingPlansPage({super.key});

  @override
  State<OnboardingPlansPage> createState() => _OnboardingPlansPageState();
}

class _OnboardingPlansPageState extends State<OnboardingPlansPage> {
  final _onboardingCubit = sl<OnboardingCubit>();
  final _authCubit = sl<AuthCubit>();
  final _nameController = TextEditingController(text: 'Anupam');
  String _selectedHub = 'Gurugram / Delhi NCR';

  static const _hubCities = [
    'Gurugram / Delhi NCR',
    'Noida Sector 62 Hub',
    'Bengaluru HSR Hub',
    'Hyderabad Madhapur Hub',
  ];

  @override
  void initState() {
    super.initState();
    final authState = _authCubit.state;
    if (authState is AuthAuthenticated) {
      _onboardingCubit.bindDriver(
        authState.user.uid,
        authState.user.phoneNumber ?? '+919876543210',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSubmitPlan(OnboardingState state) async {
    final authState = _authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final chosen = EarningScheme.byId(state.selectedPlanId);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Confirm Your Onboarding Plan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selected: ${chosen.title} (${chosen.securityDeposit} deposit)',
                    style: const TextStyle(
                      color: AppColors.incomeGold,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Driver Full Name',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter driver name',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Preferred Milo Hub',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedHub,
                    dropdownColor: AppColors.cardSurfaceElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: _hubCities
                        .map(
                          (hub) => DropdownMenuItem(
                        value: hub,
                        child: Text(hub),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => _selectedHub = val);
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                  BlocBuilder<OnboardingCubit, OnboardingState>(
                    bloc: _onboardingCubit,
                    builder: (_, liveState) {
                      return ElevatedButton(
                        onPressed: liveState.isSubmitting
                            ? null
                            : () async {
                          final ok =
                          await _onboardingCubit.submitPlanToHubOps(
                            uid: authState.user.uid,
                            planId: chosen.id,
                            driverName: _nameController.text,
                            hubCity: _selectedHub,
                          );
                          if (ok && sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                          }
                        },
                        child: liveState.isSubmitting
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Lock Plan & Submit to Hub Ops'),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      bloc: _onboardingCubit,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.miloCrimson,
              ),
            );
        }
      },
      builder: (context, state) {
        final activeScheme = EarningScheme.byId(state.selectedPlanId);
        final dailyEst = state.dailyRideEstimate;

        return Scaffold(
          backgroundColor: AppColors.canvasDark,
          body: SafeArea(
            child: Column(
              children: [
                // Top Lock Banner
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
                        Icons.lock_outline_rounded,
                        color: AppColors.lockBannerText,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Account Locked • Select a plan & complete Hub KYC to start shifts',
                          style: TextStyle(
                            color: AppColors.lockBannerText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _onboardingCubit.clear();
                          _authCubit.signOut();
                        },
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting + Milo AI Button
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Namaste, ${state.driverName} 👋',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Compare Milo EV earning schemes before visiting the hub.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => MiloAiSheet.show(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.incomeGoldBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.incomeGold
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppColors.incomeGold,
                                      size: 16,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Ask AI',
                                      style: TextStyle(
                                        color: AppColors.incomeGold,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Live Earnings Simulator Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.incomeStripBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                              AppColors.miloCrimson.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'DAILY RIDE FARE SIMULATOR',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '₹${dailyEst.round()} / day rides',
                                      style: const TextStyle(
                                        color: AppColors.incomeGold,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: dailyEst,
                                min: 1500,
                                max: 5500,
                                divisions: 16,
                                onChanged: _onboardingCubit.updateDailyEstimate,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _EarningsStat(
                                      label:
                                      '${activeScheme.shortTitle} Daily Net',
                                      amount:
                                      '₹${activeScheme.calculateDailyTakeHome(dailyEst)}',
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColors.borderSubtle,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 14),
                                      child: _EarningsStat(
                                        label: 'Est. Weekly Take-Home',
                                        amount:
                                        '₹${activeScheme.calculateWeeklyTakeHome(dailyEst)}',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                activeScheme.takeHomeFootnote,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // View Mode Toggle (Cards vs Compare Table)
                        Row(
                          children: [
                            const Text(
                              'Earning Schemes (3)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            _ViewToggleButton(
                              label: 'Cards',
                              selected: !state.isTableView,
                              onTap: () =>
                                  _onboardingCubit.toggleTableView(false),
                            ),
                            const SizedBox(width: 6),
                            _ViewToggleButton(
                              label: 'Compare Table',
                              selected: state.isTableView,
                              onTap: () =>
                                  _onboardingCubit.toggleTableView(true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (state.isTableView)
                          _buildComparisonTable(state)
                        else
                          ...EarningScheme.allSchemes.map(
                                (scheme) => _SchemeCard(
                              scheme: scheme,
                              isSelected: scheme.id == state.selectedPlanId,
                              dailyEstimate: dailyEst,
                              onTap: () =>
                                  _onboardingCubit.selectPlanLocally(scheme.id),
                              onWatchVideo: () => SchemeVideoModal.show(
                                context,
                                scheme: scheme,
                                onSelectPlan: () => _onboardingCubit
                                    .selectPlanLocally(scheme.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.cardSurface,
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _confirmAndSubmitPlan(state),
                    child: Text(
                      'Continue with ${activeScheme.title} (${activeScheme.securityDeposit})',
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

  Widget _buildComparisonTable(OnboardingState state) {
    final schemes = EarningScheme.allSchemes;
    final dailyEst = state.dailyRideEstimate;

    Widget cell(String text, {bool isHeader = false, Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        child: Text(
          text,
          style: TextStyle(
            color: color ??
                (isHeader ? AppColors.textPrimary : AppColors.textSecondary),
            fontSize: isHeader ? 12 : 11.5,
            fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: const BorderSide(color: AppColors.borderSubtle),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1.15),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.cardSurfaceElevated),
            children: [
              cell('Feature', isHeader: true),
              ...schemes.map((s) => cell(s.shortTitle, isHeader: true)),
            ],
          ),
          TableRow(
            children: [
              cell('Deposit'),
              ...schemes.map(
                    (s) => cell(s.securityDeposit, color: AppColors.incomeGold),
              ),
            ],
          ),
          TableRow(
            children: [
              cell('Plan Fee'),
              ...schemes.map((s) => cell(s.fixedDeduction)),
            ],
          ),
          TableRow(
            children: [
              cell('Charging'),
              ...schemes.map((s) => cell(s.chargingAndMaintenance)),
            ],
          ),
          TableRow(
            children: [
              cell('Est. Daily'),
              ...schemes.map(
                    (s) => cell(
                  '₹${s.calculateDailyTakeHome(dailyEst)}',
                  color: AppColors.incomeGold,
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              cell('Ownership'),
              ...schemes.map((s) => cell(s.ownershipBenefit)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final String amount;

  const _EarningsStat({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: const TextStyle(
            color: AppColors.incomeGold,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.miloCrimson : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.miloCrimsonLight : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final EarningScheme scheme;
  final bool isSelected;
  final double dailyEstimate;
  final VoidCallback onTap;
  final VoidCallback onWatchVideo;

  const _SchemeCard({
    required this.scheme,
    required this.isSelected,
    required this.dailyEstimate,
    required this.onTap,
    required this.onWatchVideo,
  });

  @override
  Widget build(BuildContext context) {
    final estDaily = scheme.calculateDailyTakeHome(dailyEstimate);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cardSurfaceElevated
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.miloCrimson : AppColors.borderSubtle,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.incomeGoldBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    scheme.badge,
                    style: const TextStyle(
                      color: AppColors.incomeGold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? AppColors.miloCrimsonLight
                      : AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    scheme.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '~₹$estDaily/day',
                      style: const TextStyle(
                        color: AppColors.incomeGold,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Est. Take-Home',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              scheme.tagline,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 12),

            // Key Metrics Row
            Row(
              children: [
                Expanded(
                  child: _MiniSpec(
                    label: 'Deposit',
                    value: scheme.securityDeposit,
                  ),
                ),
                Expanded(
                  child: _MiniSpec(
                    label: 'Terms',
                    value: scheme.fixedDeduction,
                  ),
                ),
                Expanded(
                  child: _MiniSpec(
                    label: 'Charging',
                    value: scheme.chargingAndMaintenance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Video Explainer Trigger
            InkWell(
              onTap: onWatchVideo,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.canvasDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppColors.miloCrimsonLight,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Watch ${scheme.shortTitle} Video (${scheme.videoDuration})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
  }
}

class _MiniSpec extends StatelessWidget {
  final String label;
  final String value;

  const _MiniSpec({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}