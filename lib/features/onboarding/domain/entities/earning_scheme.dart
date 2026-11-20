import 'package:equatable/equatable.dart';

class EarningScheme extends Equatable {
  final String id;
  final String title;
  final String shortTitle;
  final String badge;
  final String tagline;
  final String securityDeposit;
  final String depositNote;
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
    required this.shortTitle,
    required this.badge,
    required this.tagline,
    required this.securityDeposit,
    required this.depositNote,
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
      // Fixed base (~₹800/day) + 35% incentive on daily ride earnings above ₹2,500
        const baseDaily = 800.0;
        final bonus =
        dailyRideRevenue > 2500 ? (dailyRideRevenue - 2500) * 0.35 : 0.0;
        return (baseDaily + bonus).round();

      case 'RENTAL':
      // Driver pays ₹1,400/day rent + ~₹200/day EV charging; keeps 100% excess
        final net = dailyRideRevenue - 1400 - 200;
        return net > 0 ? net.round() : 0;

      case 'DTO':
      // ₹15,000/week EMI (~₹2,143/day over 7 days) + ~₹200/day EV charging
        final net = dailyRideRevenue - (15000 / 7) - 200;
        return net > 0 ? net.round() : 0;

      default:
        return 0;
    }
  }

  /// Calculates estimated net weekly take-home (6 active days for Salary/Rental, 7-day EMI cycle for DTO)
  int calculateWeeklyTakeHome(double dailyRideRevenue) {
    if (id == 'DTO') {
      final weeklyNet = (dailyRideRevenue * 7) - 15000 - 1400;
      return weeklyNet > 0 ? weeklyNet.round() : 0;
    }
    return calculateDailyTakeHome(dailyRideRevenue) * 6;
  }

  String get takeHomeFootnote {
    switch (id) {
      case 'SALARY':
        return 'Base ₹800/day + bonus > ₹2,500 rides (₹0 charging)';
      case 'RENTAL':
        return 'After ₹1,400 daily rent & ~₹200 EV charging';
      case 'DTO':
        return 'After ₹15,000/wk EMI & ~₹200/day charging + EV equity';
      default:
        return '';
    }
  }

  static const List<EarningScheme> allSchemes = [
    EarningScheme(
      id: 'SALARY',
      title: 'Salary Model',
      shortTitle: 'Salary',
      badge: 'ZERO VEHICLE RISK',
      tagline: 'Guaranteed monthly salary + extra incentives above ₹2,500/day rides.',
      securityDeposit: '₹6,000',
      depositNote: '₹2k–₹3k hub exception available',
      fixedDeduction: '100% Rides to Milo',
      chargingAndMaintenance: '₹0 (Covered by Milo)',
      ownershipBenefit: 'Company Fleet EV',
      englishSummary:
      'Remit 100% of daily ride fares to Milo and receive a fixed salary plus performance incentives whenever your daily ride revenue crosses ₹2,500. Milo pays for all EV charging and servicing.',
      hindiSummary:
      'Rozana ki poori ride kamai Milo ko jama karein aur fixed salary payein. ₹2,500/din se zyada kaam karne par extra incentive milega. Charging aur maintenance ka kharcha poora Milo uthayega.',
      videoUrl:
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      videoDuration: '0:45',
    ),
    EarningScheme(
      id: 'RENTAL',
      title: 'Rental Model',
      shortTitle: 'Rental',
      badge: 'MOST FLEXIBLE',
      tagline: 'Pay ₹1,400/day flat rent and keep 100% of every rupee above it.',
      securityDeposit: '₹10,000',
      depositNote: 'Refundable upon vehicle return',
      fixedDeduction: '₹1,400 / day',
      chargingAndMaintenance: 'Driver Paid',
      ownershipBenefit: 'Daily Rental EV',
      englishSummary:
      'Pay a flat ₹1,400 daily prepaid rental fee and keep 100% of your ride earnings above ₹1,400. Ideal for high-hour drivers who want maximum daily cash take-home without long-term lock-in.',
      hindiSummary:
      'Sirf ₹1,400/din ka fixed rent dein aur uske upar ki 100% kamai apne paas rakhein. Charging aur routine maintenance driver ki zimmedari hogi.',
      videoUrl:
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      videoDuration: '0:50',
    ),
    EarningScheme(
      id: 'DTO',
      title: 'Drive to Own',
      shortTitle: 'Drive to Own',
      badge: 'OWN YOUR EV',
      tagline: 'Pay ₹15,000/week EMI, keep surplus rides, and own the car at term end.',
      securityDeposit: '₹40,000',
      depositNote: 'One-time ownership down payment',
      fixedDeduction: '₹15,000 / week',
      chargingAndMaintenance: 'Driver Paid',
      ownershipBenefit: 'Full RC Transfer',
      englishSummary:
      'Build asset ownership while driving. Pay a ₹40,000 security deposit and ₹15,000 weekly EMI, keep all excess ride earnings, and receive full vehicle ownership transfer after repayment.',
      hindiSummary:
      '₹40,000 deposit aur ₹15,000/hafte ki EMI bharein. Bachi hui saari kamai aapki hogi aur poori EMI bharne ke baad gaadi aapke naam transfer ho jayegi.',
      videoUrl:
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoy.mp4',
      videoDuration: '1:05',
    ),
  ];

  static EarningScheme byId(String? id) {
    return allSchemes.firstWhere(
          (scheme) => scheme.id == id,
      orElse: () => allSchemes[1], // Default highlight: Rental Model
    );
  }

  @override
  List<Object?> get props => [id, title, securityDeposit, fixedDeduction];
}