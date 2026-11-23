import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/earning_scheme.dart';

enum AiLanguage { english, hinglish }

class AiChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final String? recommendedPlanId;
  final DateTime timestamp;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    this.recommendedPlanId,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, isUser, recommendedPlanId, timestamp];
}

class MiloAiState extends Equatable {
  final AiLanguage language;
  final List<AiChatMessage> messages;

  const MiloAiState({
    required this.language,
    required this.messages,
  });

  MiloAiState copyWith({
    AiLanguage? language,
    List<AiChatMessage>? messages,
  }) {
    return MiloAiState(
      language: language ?? this.language,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [language, messages];
}

class _GeneratedAiReply {
  final String text;
  final String? recommendedPlanId;

  const _GeneratedAiReply(this.text, {this.recommendedPlanId});
}

class MiloAiCubit extends Cubit<MiloAiState> {
  MiloAiCubit()
      : super(
    MiloAiState(
      language: AiLanguage.english,
      messages: [
        AiChatMessage(
          text:
          'Hi! I am **Milo Saathi AI** 🤖⚡\n\nAsk me anything about daily/weekly take-home earnings, the Salary ₹2k–3k deposit exception, EV charging, or owning your car with **DTO**.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    ),
  );

  void switchLanguage(AiLanguage newLang) {
    if (state.language == newLang) return;
    final greeting = newLang == AiLanguage.english
        ? 'Switched to **English**. Ask me anything about take-home earnings, deposits, or **DTO** ownership!'
        : '**Hinglish** mode chalu ho gaya hai! Aap daily/weekly kamai, ₹2k–3k deposit exception, ya **DTO** ke baare mein pooch sakte hain.';

    emit(
      state.copyWith(
        language: newLang,
        messages: [
          ...state.messages,
          AiChatMessage(
            text: greeting,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      ),
    );
  }

  void askQuestion(String prompt, {required double currentDailyEstimate}) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final userMsg = AiChatMessage(
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final reply = _generateReply(
      trimmed.toLowerCase(),
      dailyEstimate: currentDailyEstimate,
      isHinglish: state.language == AiLanguage.hinglish,
    );

    final botMsg = AiChatMessage(
      text: reply.text,
      isUser: false,
      recommendedPlanId: reply.recommendedPlanId,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(messages: [...state.messages, userMsg, botMsg]));
  }

  _GeneratedAiReply _generateReply(
      String q, {
        required double dailyEstimate,
        required bool isHinglish,
      }) {
    final salary = EarningScheme.byId('SALARY');
    final rental = EarningScheme.byId('RENTAL');
    final dto = EarningScheme.byId('DTO');

    final estStr = EarningScheme.formatRupees(dailyEstimate);
    final salDailyStr =
    EarningScheme.formatRupees(salary.calculateDailyTakeHome(dailyEstimate));
    final renDailyStr =
    EarningScheme.formatRupees(rental.calculateDailyTakeHome(dailyEstimate));
    final dtoWeeklyStr =
    EarningScheme.formatRupees(dto.calculateWeeklyTakeHome(dailyEstimate));

    // 1. Highest Income / Earnings Comparison
    if (q.contains('earn') ||
        q.contains('income') ||
        q.contains('highest') ||
        q.contains('kamai') ||
        q.contains('kitna') ||
        q.contains('calculate')) {
      return _GeneratedAiReply(
        isHinglish
            ? '💰 **$estStr/day** rides par aapki take-home kamai:\n\n'
            '1. **Rental Model:** ₹1,400/day ke upar 100% aapka → **$renDailyStr/day**.\n'
            '2. **Drive to Own (DTO):** ₹15,000/wk EMI ke upar → **$dtoWeeklyStr/wk** PLUS **100% Car Ownership!**\n'
            '3. **Salary Model:** **$salDailyStr/day** aur ₹0 fuel & maintenance kharcha.'
            : '💰 **Take-home comparison at $estStr/day rides:**\n\n'
            '1. **Rental Model:** Keep 100% above ₹1,400/day → **$renDailyStr/day**.\n'
            '2. **Drive to Own (DTO):** Keep excess above ₹15,000/wk EMI → **$dtoWeeklyStr/wk** PLUS **100% Car Ownership!**\n'
            '3. **Salary Model:** **$salDailyStr/day** with **₹0 fuel & maintenance costs.**',
        recommendedPlanId: 'RENTAL',
      );
    }

    // 2. Deposit / Exception Query
    if (q.contains('deposit') ||
        q.contains('2k') ||
        q.contains('3k') ||
        q.contains('exception') ||
        q.contains('jama')) {
      return _GeneratedAiReply(
        isHinglish
            ? '🛡️ **Security Deposit & Hub Exception:**\n\n'
            '• **Salary Model:** Standard deposit **₹6,000** hai, lekin Hub Ops approval par **₹2,000–₹3,000** ka flex exception mil sakta hai.\n'
            '• **Rental Model:** **₹10,000** (100% refundable).\n'
            '• **Drive to Own:** **₹40,000** one-time down payment.'
            : '🛡️ **Security Deposit & Hub Exception:**\n\n'
            '• **Salary Model:** Standard deposit is **₹6,000**, with a **₹2k–3k flex exception** available at Hub Ops.\n'
            '• **Rental Model:** **₹10,000** (100% refundable).\n'
            '• **Drive to Own:** **₹40,000** one-time down payment.',
        recommendedPlanId: 'SALARY',
      );
    }

    // 3. Charging & Maintenance Query
    if (q.contains('charg') ||
        q.contains('maint') ||
        q.contains('fuel') ||
        q.contains('service')) {
      return _GeneratedAiReply(
        isHinglish
            ? '⚡ **Charging & Maintenance:**\n\n'
            '• **Salary Model:** **₹0** driver cost — poori EV charging aur maintenance Milo cover karta hai.\n'
            '• **Rental & DTO:** Charging aur routine maintenance driver khud pay karta hai.'
            : '⚡ **Charging & Maintenance:**\n\n'
            '• **Salary Model:** **₹0** driver cost — Milo covers 100% of EV charging and servicing.\n'
            '• **Rental & DTO:** Charging and routine maintenance are driver-paid.',
        recommendedPlanId: 'SALARY',
      );
    }

    // 4. Drive to Own Query
    if (q.contains('own') ||
        q.contains('dto') ||
        q.contains('emi') ||
        q.contains('malik')) {
      return _GeneratedAiReply(
        isHinglish
            ? '🚘 **Drive to Own (DTO):**\n\n'
            '• **₹40,000** down payment aur **₹15,000/week** EMI bharein.\n'
            '• EMI ke upar ki saari kamai (**$dtoWeeklyStr/wk**) aapki hai, aur term poora hone par **100% RC Transfer** aapke naam hoga.'
            : '🚘 **Drive to Own (DTO):**\n\n'
            '• Pay **₹40,000** down payment and **₹15,000/week** EMI.\n'
            '• Keep all surplus ride earnings (**$dtoWeeklyStr/wk**) and get **100% RC Transfer** at term end.',
        recommendedPlanId: 'DTO',
      );
    }

    // 5. Default Recommendation
    return _GeneratedAiReply(
      isHinglish
          ? 'Aapke goal ke hisaab se best plan:\n\n'
          '• **Salary Model:** **$salDailyStr/day** + ₹0 charging risk.\n'
          '• **Rental Model:** **$renDailyStr/day** highest daily cash.\n'
          '• **Drive to Own:** **$dtoWeeklyStr/wk** + apni khud ki EV.'
          : 'Here is how the 3 plans compare at **$estStr/day**:\n\n'
          '• **Salary Model:** **$salDailyStr/day** with ₹0 fuel/maint. cost.\n'
          '• **Rental Model:** **$renDailyStr/day** maximum daily take-home.\n'
          '• **Drive to Own:** **$dtoWeeklyStr/wk** + 100% car ownership.',
      recommendedPlanId: 'SALARY',
    );
  }
}