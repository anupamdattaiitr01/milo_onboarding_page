import 'package:equatable/equatable.dart';

class EarningScheme extends Equatable {
  final String id;
  final String title;
  final String uppercaseTitle;
  final String shortTitle;
  final String badge;
  final bool isGoldBadge;
  final String earningModelTitle;
  final String takeHomeSubtext;
  final String targetLabel;
  final String targetValue;
  final String securityDeposit;
  final String depositSummary;
  final String fixedDeduction;
  final String chargingAndMaintenance;
  final String ownershipBenefit;
  final String englishSummary;
  final String hindiSummary;
  final String videoUrl;
  final String videoDuration;

  const EarningScheme({
    required this.id,
    required this.title,
    required this.uppercaseTitle,
    required this.shortTitle,
    required this.badge,
    required this.isGoldBadge,
    required this.earningModelTitle,
    required this.takeHomeSubtext,
    required this.targetLabel,
    required this.targetValue,
    required this.securityDeposit,
    required this.depositSummary,
    required this.fixedDeduction,
    required this.chargingAndMaintenance,
    required this.ownershipBenefit,
    required this.englishSummary,
    required this.hindiSummary,
    required this.videoUrl,
    required this.videoDuration,
  });

  /// Calculates estimated net daily take-home based on gross daily ride revenue
  int calculateDailyTakeHome(double dailyRideRevenue) {
    switch (id) {
      case 'SALARY':
      // ₹800/day base + 70% incentive above ₹2,500/day (₹3,000/day -> ₹1,150/day)
        const baseDaily = 800.0;
        final bonus =
        dailyRideRevenue > 2500 ? (dailyRideRevenue - 2500) * 0.70 : 0.0;
        return (baseDaily + bonus).round();

      case 'RENTAL':
      // Keep 100% of ride revenue above ₹1,400/day flat rent (₹3,000/day -> ₹1,600/day)
        final net = dailyRideRevenue - 1400;
        return net > 0 ? net.round() : 0;

      case 'DTO':
      // Daily equivalent surplus after ₹15,000/week EMI
        final net = dailyRideRevenue - (15000 / 7);
        return net > 0 ? net.round() : 0;

      default:
        return 0;
    }
  }

  /// Calculates estimated net weekly take-home (7-day cycle for DTO: ₹3,000/day -> ₹6,000/wk)
  int calculateWeeklyTakeHome(double dailyRideRevenue) {
    if (id == 'DTO') {
      final weeklyNet = (dailyRideRevenue * 7) - 15000;
      return weeklyNet > 0 ? weeklyNet.round() : 0;
    }
    return calculateDailyTakeHome(dailyRideRevenue) * 6;
  }

  static const List<EarningScheme> allSchemes = [
    EarningScheme(
      id: 'SALARY',
      title: 'Salary Model',
      uppercaseTitle: 'SALARY MODEL',
      shortTitle: 'Salary',
      badge: 'FIXED PAY',
      isGoldBadge: false,
      earningModelTitle: 'Fixed Salary +\nBonus',
      takeHomeSubtext: 'Zero fuel/maint. cost',
      targetLabel: 'Daily Target',
      targetValue: '₹2,500 (to Milo)',
      securityDeposit: '₹6,000',
      depositSummary: '₹6,000 (₹2k–3k flex)',
      fixedDeduction: '100% Rides to Milo',
      chargingAndMaintenance: '₹0 (Covered by Milo)',
      ownershipBenefit: 'Milo Fleet',
      englishSummary:
      'Remit daily rides up to ₹2,500 to Milo and earn a guaranteed base salary plus 70% bonus on every rupee above ₹2,500/day. Milo covers 100% of EV charging and servicing.',
      hindiSummary:
      'Rozana ₹2,500 tak ki rides Milo ko jama karein aur fixed salary payein. ₹2,500/din se upar ki kamai par 70% bonus milega. Charging aur maintenance ka kharcha poora Milo uthayega.',
      videoUrl:
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      videoDuration: '01:20',
    ),
    EarningScheme(
      id: 'RENTAL',
      title: 'Rental Model',
      uppercaseTitle: 'RENTAL MODEL',
      shortTitle: 'Rental',
      badge: 'FLEXIBLE',
      isGoldBadge: true,
      earningModelTitle: 'Daily Flat\nRent',
      takeHomeSubtext: 'Keep 100% above ₹1,400',
      targetLabel: 'Daily Rent',
      targetValue: '₹1,400 / day',
      securityDeposit: '₹10,000',
      depositSummary: '₹10,000 (Refundable)',
      fixedDeduction: '₹1,400 / day',
      chargingAndMaintenance: 'Driver Paid',
      ownershipBenefit: 'Daily Rental EV',
      englishSummary:
      'Pay a flat ₹1,400 daily rental fee and keep 100% of every rupee earned above ₹1,400. Ideal for drivers who want maximum daily cash take-home without long-term lock-in.',
      hindiSummary:
      'Sirf ₹1,400/din ka fixed rent dein aur uske upar ki 100% kamai apne paas rakhein. Charging aur routine maintenance driver ki zimmedari hogi.',
      videoUrl:
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      videoDuration: '01:05',
    ),
    EarningScheme(
      id: 'DTO',
      title: 'Drive to Own',
      uppercaseTitle: 'DRIVE TO OWN',
      shortTitle: 'Drive to Own',
      badge: 'OWN YOUR EV',
      isGoldBadge: true,
      earningModelTitle: 'Weekly EMI to\nOwnership',
      takeHomeSubtext: 'After ₹15,000/wk EMI',
      targetLabel: 'Weekly EMI',
      targetValue: '₹15,000 / week',
      securityDeposit: '₹40,000',
      depositSummary: '₹40,000 (Down payment)',
      fixedDeduction: '₹15,000 / week',
      chargingAndMaintenance: 'Driver Paid',
      ownershipBenefit: '100% RC Transfer',
      englishSummary:
      'Pay a ₹40,000 down payment and ₹15,000 weekly EMI, keep all excess ride earnings, and receive 100% vehicle RC ownership transfer at term end.',
      hindiSummary:
      '₹40,000 deposit aur ₹15,000/hafte ki EMI bharein. Bachi hui saari kamai aapki hogi aur poori EMI complete hone par gaadi ki RC aapke naam transfer ho jayegi.',
      videoUrl:
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoy.mp4',
      videoDuration: '01:35',
    ),
  ];

  static EarningScheme byId(String? id) {
    return allSchemes.firstWhere(
          (scheme) => scheme.id == id,
      orElse: () => allSchemes[0],
    );
  }

  static String formatRupees(num value) {
    final str = value.round().toString();
    if (str.length <= 3) return '₹$str';
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    final formattedPrefix = remaining.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
          (match) => '${match[1]},',
    );
    return '₹$formattedPrefix,$lastThree';
  }

  @override
  List<Object?> get props => [id, title, securityDeposit, fixedDeduction];
}