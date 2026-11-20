import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/earning_scheme.dart';

enum AiLanguage { english, hinglish }

class AiChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, isUser, timestamp];
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

class MiloAiCubit extends Cubit<MiloAiState> {
  MiloAiCubit()
      : super(
    MiloAiState(
      language: AiLanguage.english,
      messages: [
        AiChatMessage(
          text:
          'Namaste Anupam! I am Milo Saathi AI. Ask me anything about Salary, Rental, or Drive-to-Own plans, security deposits, or your daily take-home earnings.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    ),
  );

  void switchLanguage(AiLanguage newLang) {
    if (state.language == newLang) return;
    final greeting = newLang == AiLanguage.english
        ? 'Switched to English. How can I help you compare Milo plans?'
        : 'Hinglish mode chalu ho gaya hai! Aap Salary, Rental, ya Drive-to-Own plan ke baare mein kuch bhi pooch sakte hain.';

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

    final replyText = _generateReply(
      trimmed.toLowerCase(),
      dailyEstimate: currentDailyEstimate,
      isHinglish: state.language == AiLanguage.hinglish,
    );

    final botMsg = AiChatMessage(
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(messages: [...state.messages, userMsg, botMsg]));
  }

  String _generateReply(
      String q, {
        required double dailyEstimate,
        required bool isHinglish,
      }) {
    final salary = EarningScheme.byId('SALARY');
    final rental = EarningScheme.byId('RENTAL');
    final dto = EarningScheme.byId('DTO');

    final est = dailyEstimate.round();
    final salDaily = salary.calculateDailyTakeHome(dailyEstimate);
    final renDaily = rental.calculateDailyTakeHome(dailyEstimate);
    final dtoWeekly = dto.calculateWeeklyTakeHome(dailyEstimate);

    // 1. Income / Calculation Query
    if (q.contains('earn') ||
        q.contains('income') ||
        q.contains('kamai') ||
        q.contains('kitna') ||
        q.contains('calculate')) {
      return isHinglish
          ? 'Agar aap roz ₹$est ki rides karte hain:\n'
          '• Rental Model: ~₹$renDaily/din (sabse zyada cash take-home)\n'
          '• Salary Model: ~₹$salDaily/din (zero charging tension)\n'
          '• Drive to Own: ~₹$dtoWeekly/hafta + gaadi aapki hoti jayegi!'
          : 'At ₹$est/day in gross rides, your estimated net take-home is:\n'
          '• Rental Model: ~₹$renDaily/day (highest daily cash surplus)\n'
          '• Salary Model: ~₹$salDaily/day (with ₹0 charging/service cost)\n'
          '• Drive to Own: ~₹$dtoWeekly/week after ₹15,000 EMI + vehicle ownership equity.';
    }

    // 2. Deposit Query
    if (q.contains('deposit') || q.contains('jama') || q.contains('security')) {
      return isHinglish
          ? 'Security Deposit details:\n'
          '• Salary Model: ₹6,000 (Hub approval par ₹2k–₹3k exception bhi mil sakta hai)\n'
          '• Rental Model: ₹10,000 (refundable)\n'
          '• Drive to Own: ₹40,000 (one-time ownership deposit)'
          : 'Security deposit requirements by plan:\n'
          '• Salary Model: ₹6,000 (₹2k–₹3k hub exception available)\n'
          '• Rental Model: ₹10,000 (refundable on return)\n'
          '• Drive to Own: ₹40,000 (one-time ownership down payment)';
    }

    // 3. Charging & Maintenance Query
    if (q.contains('charg') ||
        q.contains('maint') ||
        q.contains('service') ||
        q.contains('kharcha')) {
      return isHinglish
          ? 'Salary Model mein EV charging aur maintenance ka 100% kharcha Milo uthata hai (₹0 driver cost). Rental aur Drive-to-Own mein charging aur routine maintenance driver khud pay karta hai.'
          : 'In the Salary Model, Milo covers 100% of EV charging and maintenance (₹0 cost to you). In Rental and Drive-to-Own, charging and routine maintenance are paid by the driver.';
    }

    // 4. Drive to Own Query
    if (q.contains('own') ||
        q.contains('dto') ||
        q.contains('emi') ||
        q.contains('malik')) {
      return isHinglish
          ? 'Drive to Own mein ₹40,000 deposit aur ₹15,000/hafte ki EMI lagti hai. EMI ke upar ki saari ride kamai aapki hai, aur poori EMI complete hone par gaadi ki RC aapke naam transfer ho jati hai.'
          : 'Drive to Own requires a ₹40,000 deposit and ₹15,000/week EMI. You keep all ride earnings above the weekly EMI, and full vehicle ownership transfers to you upon completing repayment.';
    }

    // 5. Default Recommendation
    return isHinglish
        ? 'Best plan aapke goal par depend karta hai:\n'
        '• Bina kisi risk aur charging kharche ke kaam karna hai -> Salary Model (₹6,000 deposit)\n'
        '• Rozana sabse zyada cash kamana hai -> Rental Model (₹1,400/din)\n'
        '• Apni khud ki EV gaadi banani hai -> Drive to Own (₹15,000/wk EMI)'
        : 'Choose based on your goal:\n'
        '• Zero expense risk & fixed pay -> Salary Model (₹6,000 deposit)\n'
        '• Maximum daily cash take-home -> Rental Model (₹1,400/day)\n'
        '• Long-term car ownership -> Drive to Own (₹15,000/week EMI)';
  }
}