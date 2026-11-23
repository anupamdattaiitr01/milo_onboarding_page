import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/widgets/milo_brand_logo.dart';
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
    final planId = state.selectedPlanId;
    if (planId == null) return;

    final authState = _authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final chosen = EarningScheme.byId(planId);

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
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                        ),
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
        final hasSelection = state.selectedPlanId != null;
        final selectedScheme =
        hasSelection ? EarningScheme.byId(state.selectedPlanId) : null;
        final dailyEst = state.dailyRideEstimate.clamp(2000.0, 4500.0);

        return Scaffold(
          backgroundColor: AppColors.canvasDark,
          body: SafeArea(
            child: Column(
              children: [
                // Top Brand Header Row (Exit | Milo Logo | AI Help)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Logout / Exit Icon Button
                      GestureDetector(
                        onTap: () => showLogoutConfirmationDialog(
                          context,
                          onConfirmLogout: () {
                            _onboardingCubit.clear();
                            _authCubit.signOut();
                          },
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),

                      // Centered Milo Drive PNG Logo
                      const MiloBrandLogo(height: 36),

                      // Right 'AI Help' Pill Button
                      GestureDetector(
                        onTap: () => MiloAiSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.smart_toy_rounded,
                                color: Color(0xFF8AB4F8),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'AI Help',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
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
                ),

                // Locked Status Pill Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lockBannerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lockBannerBorder),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: AppColors.incomeGold,
                          size: 14,
                        ),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Onboarding Locked • Select a plan to connect with Hub Ops',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.lockBannerText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Scrollable Content + Floating 'Ask Milo AI' Pill
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 76),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Plans / Compare Table Toggle
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Choose Your Earning Plan',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _SegmentPill(
                                        label: 'Plans',
                                        selected: !state.isTableView,
                                        onTap: () => _onboardingCubit
                                            .toggleTableView(false),
                                      ),
                                      _SegmentPill(
                                        label: 'Compare Table',
                                        selected: state.isTableView,
                                        onTap: () => _onboardingCubit
                                            .toggleTableView(true),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Daily Ride Earnings Slider Card
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Daily Ride Earnings',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF282012),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.incomeGold
                                                .withValues(alpha: 0.55),
                                          ),
                                        ),
                                        child: Text(
                                          '${EarningScheme.formatRupees(dailyEst)}/day',
                                          style: const TextStyle(
                                            color: AppColors.incomeGold,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      activeTrackColor: AppColors.miloCrimson,
                                      inactiveTrackColor:
                                      const Color(0xFF2C2C34),
                                      thumbColor: AppColors.incomeGold,
                                      overlayColor: AppColors.miloCrimson
                                          .withValues(alpha: 0.2),
                                      thumbShape: const _RingSliderThumbShape(),
                                    ),
                                    child: Slider(
                                      value: dailyEst,
                                      min: 2000,
                                      max: 4500,
                                      divisions: 25,
                                      onChanged:
                                      _onboardingCubit.updateDailyEstimate,
                                    ),
                                  ),
                                  const Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹2,000',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'Slide to calculate take-home',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      Text(
                                        '₹4,500/day',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Plans List or Compare Table
                            if (state.isTableView)
                              _buildComparisonTable(state, dailyEst)
                            else
                              ...EarningScheme.allSchemes.map(
                                    (scheme) => _SchemeCard(
                                  scheme: scheme,
                                  isSelected: scheme.id == state.selectedPlanId,
                                  dailyEstimate: dailyEst,
                                  onTap: () => _onboardingCubit
                                      .selectPlanLocally(scheme.id),
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

                      // Floating 'Ask Milo AI' Pill on Bottom Right
                      Positioned(
                        right: 16,
                        bottom: 12,
                        child: GestureDetector(
                          onTap: () => MiloAiSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F161B),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFB82954),
                                width: 1.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.miloCrimson
                                      .withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'Ask Milo AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sticky Bottom Confirmation Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF141418),
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            hasSelection
                                ? 'Selected: ${selectedScheme!.title}'
                                : 'Tap a plan card above to select',
                            style: TextStyle(
                              color: hasSelection
                                  ? AppColors.textPrimary
                                  : const Color(0xFFA85870),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            hasSelection
                                ? 'Deposit ${selectedScheme!.securityDeposit}'
                                : '0/1',
                            style: TextStyle(
                              color: hasSelection
                                  ? AppColors.incomeGold
                                  : AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: hasSelection
                            ? () => _confirmAndSubmitPlan(state)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: hasSelection
                                ? const LinearGradient(
                              colors: [
                                Color(0xFFB82954),
                                Color(0xFF8C1C40),
                              ],
                            )
                                : null,
                            color:
                            hasSelection ? null : const Color(0xFF28282E),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_rounded,
                                color: hasSelection
                                    ? Colors.white
                                    : AppColors.textMuted,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confirm & Reach Out to Hub Ops',
                                style: TextStyle(
                                  color: hasSelection
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonTable(OnboardingState state, double dailyEst) {
    final schemes = EarningScheme.allSchemes;

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
                  '${EarningScheme.formatRupees(s.calculateDailyTakeHome(dailyEst))}/day',
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

class _SegmentPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB82954) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
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
    final estDaily =
    EarningScheme.formatRupees(scheme.calculateDailyTakeHome(dailyEstimate));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1418) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB82954)
                : AppColors.borderSubtle,
            width: isSelected ? 1.8 : 1.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header: Radio + Uppercase Title + Right Badge
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? const Color(0xFFD63B68)
                      : AppColors.textMuted,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scheme.uppercaseTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.isGoldBadge
                        ? const Color(0xFF282012)
                        : const Color(0xFF2E151E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.isGoldBadge
                          ? AppColors.incomeGold.withValues(alpha: 0.45)
                          : const Color(0xFF6B243B),
                    ),
                  ),
                  child: Text(
                    scheme.badge,
                    style: TextStyle(
                      color: scheme.isGoldBadge
                          ? AppColors.incomeGold
                          : const Color(0xFFE57A9B),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Highlighted Split Box: EST. TAKE-HOME | EARNING MODEL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF231319),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3A1D28)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EST. TAKE-HOME',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$estDaily/day',
                            style: const TextStyle(
                              color: AppColors.incomeGold,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scheme.takeHomeSubtext,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFF3A1D28),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EARNING MODEL',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scheme.earningModelTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2x2 Spec Grid
            Row(
              children: [
                Expanded(
                  child: _SpecBlock(
                    label: 'Security Deposit',
                    value: scheme.depositSummary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SpecBlock(
                    label: scheme.targetLabel,
                    value: scheme.targetValue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SpecBlock(
                    label: 'Charging & Maint.',
                    value: scheme.chargingAndMaintenance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SpecBlock(
                    label: 'Car Ownership',
                    value: scheme.ownershipBenefit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Embedded Video Preview Row
            InkWell(
              onTap: onWatchVideo,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    // Mini Video Thumbnail
                    Container(
                      width: 58,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2B161E), Color(0xFF1A1A20)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF47212E)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            right: 4,
                            bottom: 2,
                            child: Icon(
                              Icons.directions_car_filled_rounded,
                              color: Colors.white.withValues(alpha: 0.25),
                              size: 20,
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFB82954),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watch: How ${scheme.title} Works',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hindi & English • ${scheme.videoDuration}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
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

class _SpecBlock extends StatelessWidget {
  final String label;
  final String value;

  const _SpecBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Custom double-ring slider thumb matching the gold/crimson ring handle.
class _RingSliderThumbShape extends SliderComponentShape {
  const _RingSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final canvas = context.canvas;

    // Outer gold ring
    canvas.drawCircle(
      center,
      11,
      Paint()..color = AppColors.incomeGold,
    );
    // Middle crimson ring
    canvas.drawCircle(
      center,
      8.5,
      Paint()..color = const Color(0xFFB82954),
    );
    // Inner dark center
    canvas.drawCircle(
      center,
      5,
      Paint()..color = const Color(0xFF18181D),
    );
  }
}