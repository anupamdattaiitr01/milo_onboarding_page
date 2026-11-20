import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/milo_ai_cubit.dart';
import '../bloc/onboarding_cubit.dart';

class MiloAiSheet extends StatefulWidget {
  const MiloAiSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MiloAiSheet(),
    );
  }

  @override
  State<MiloAiSheet> createState() => _MiloAiSheetState();
}

class _MiloAiSheetState extends State<MiloAiSheet> {
  final _aiCubit = sl<MiloAiCubit>();
  final _onboardingCubit = sl<OnboardingCubit>();
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  static const _quickPrompts = [
    'How much will I earn?',
    'Security deposit details?',
    'Who pays EV charging?',
    'How does Drive to Own work?',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendPrompt([String? preset]) {
    final text = preset ?? _promptController.text;
    if (text.trim().isEmpty) return;

    _aiCubit.askQuestion(
      text,
      currentDailyEstimate: _onboardingCubit.state.dailyRideEstimate,
    );
    if (preset == null) _promptController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: BlocBuilder<MiloAiCubit, MiloAiState>(
          bloc: _aiCubit,
          builder: (context, state) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.incomeGoldBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.incomeGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Milo Saathi AI',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Instant Plan & Earnings Advisor',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // English / Hinglish Toggle
                      _LanguagePill(
                        label: 'EN',
                        active: state.language == AiLanguage.english,
                        onTap: () => _aiCubit.switchLanguage(AiLanguage.english),
                      ),
                      const SizedBox(width: 6),
                      _LanguagePill(
                        label: 'Hinglish',
                        active: state.language == AiLanguage.hinglish,
                        onTap: () =>
                            _aiCubit.switchLanguage(AiLanguage.hinglish),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),

                // Chat History
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? AppColors.miloCrimson
                                : AppColors.cardSurfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: msg.isUser
                                ? null
                                : Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            msg.text,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Quick Question Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _quickPrompts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final q = _quickPrompts[index];
                      return ActionChip(
                        backgroundColor: AppColors.cardSurfaceElevated,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        label: Text(
                          q,
                          style: const TextStyle(
                            color: AppColors.incomeGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _sendPrompt(q),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Prompt Input Bar
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promptController,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Ask about deposit, EMI, or income...',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendPrompt(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => _sendPrompt(),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.miloCrimson,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _LanguagePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.incomeGoldBg : AppColors.cardSurfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.incomeGold : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.incomeGold : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}