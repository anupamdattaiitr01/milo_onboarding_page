import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/earning_scheme.dart';
import '../bloc/milo_ai_cubit.dart';
import '../bloc/onboarding_cubit.dart';

class MiloAiSheet extends StatefulWidget {
  const MiloAiSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141418),
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
    'Which plan gives highest income?',
    'Salary ₹2k–3k deposit exception?',
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
        height: MediaQuery.of(context).size.height * 0.78,
        child: BlocBuilder<MiloAiCubit, MiloAiState>(
          bloc: _aiCubit,
          builder: (context, state) {
            return ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              child: Column(
                children: [
                  // Dark Burgundy Top Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF28131B),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF421F2C)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Bot Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1519),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.miloCrimsonLight
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Color(0xFF8AB4F8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title + LIVE pill + Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Milo Saathi AI',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF362815),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: AppColors.incomeGold
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: AppColors.incomeGold,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Ask about earnings, deposit & DTO ownership',
                                maxLines: 2,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // English / Hinglish Segmented Pill
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1115),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF421F2C)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LangOption(
                                label: 'English',
                                active: state.language == AiLanguage.english,
                                onTap: () =>
                                    _aiCubit.switchLanguage(AiLanguage.english),
                              ),
                              _LangOption(
                                label: 'हिंदी\n(Hinglish)',
                                active: state.language == AiLanguage.hinglish,
                                onTap: () => _aiCubit
                                    .switchLanguage(AiLanguage.hinglish),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Close Button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFF38222B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat Stream
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        if (msg.isUser) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                MediaQuery.of(context).size.width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.miloCrimson,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                msg.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        }

                        final recommendedScheme = msg.recommendedPlanId != null
                            ? EarningScheme.byId(msg.recommendedPlanId)
                            : null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D1A20),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.miloCrimsonLight
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.smart_toy_rounded,
                                  color: Color(0xFF8AB4F8),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B1B20),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      _FormattedRichText(msg.text),
                                      if (recommendedScheme != null) ...[
                                        const SizedBox(height: 14),
                                        InkWell(
                                          onTap: () {
                                            _onboardingCubit.selectPlanLocally(
                                              recommendedScheme.id,
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 11,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF26131A),
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF7D2742),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  '✓ Select This Plan (${recommendedScheme.title})',
                                                  style: const TextStyle(
                                                    color: Color(0xFFF3A6BE),
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const Text(
                                                  '→',
                                                  style: TextStyle(
                                                    color: Color(0xFFF3A6BE),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Quick Questions & Input Section
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF141418),
                      border: Border(
                        top: BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUICK QUESTIONS:',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _quickPrompts.length,
                              separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final q = _quickPrompts[index];
                                return GestureDetector(
                                  onTap: () => _sendPrompt(q),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B1B20),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    child: Text(
                                      q,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promptController,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                    'Ask about income, deposit, or DTO...',
                                    hintStyle: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1B1B20),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.miloCrimsonLight,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendPrompt(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _sendPrompt(),
                                child: Container(
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB82954),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Send',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFB82954) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

/// Renders `**bold**` spans cleanly inside AI messages.
class _FormattedRichText extends StatelessWidget {
  final String rawText;

  const _FormattedRichText(this.rawText);

  @override
  Widget build(BuildContext context) {
    final parts = rawText.split('**');
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      final isBold = i.isOdd;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            height: 1.45,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}