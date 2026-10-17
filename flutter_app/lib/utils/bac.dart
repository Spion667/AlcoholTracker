import '../models/body_profile.dart';
import '../models/drink.dart';

/// Promille-Rechner (BAC-Engine): Watson-Formel (1980) & Zeitkinetik-Simulation.
/// Spiegel von `src/utils/bac.js`.

/// Leber-Eliminationsrate: forensischer Standardmittelwert 0,12 ‰ pro Stunde.
const bacMetabolismPerHour = 0.12;
const bacMetabolismPerMinute = bacMetabolismPerHour / 60;

/// Dauer der Resorptionsphase pro Drink (Minuten).
const absorptionDurationMinutes = 30;

/// Gesamtkoerperwasser (Total Body Water) in Litern nach Watson (1980).
double calculateTbw({
  required String gender,
  num? age,
  num? heightCm,
  num? weightKg,
}) {
  final ageNum = (age == null || age == 0) ? 25 : age;
  final heightNum = (heightCm == null || heightCm == 0) ? 175 : heightCm;
  final weightNum = (weightKg == null || weightKg == 0) ? 70 : weightKg;

  final tbwMale =
      2.447 - 0.09516 * ageNum + 0.1074 * heightNum + 0.3362 * weightNum;
  final tbwFemale = -2.097 + 0.1069 * heightNum + 0.2466 * weightNum;

  if (gender == 'female') return tbwFemale < 10 ? 10 : tbwFemale;
  if (gender == 'other') {
    final avg = (tbwMale + tbwFemale) / 2;
    return avg < 10 ? 10 : avg;
  }
  return tbwMale < 10 ? 10 : tbwMale;
}

class BacResult {
  const BacResult({
    this.currentBac = 0,
    this.formattedBac = '0,0 ‰',
    this.peakBac = 0,
    this.peakTime,
    this.soberTime,
    this.soberTimeString = '',
    this.isZero = true,
  });

  final double currentBac;
  final String formattedBac;
  final double peakBac;
  final DateTime? peakTime;
  final DateTime? soberTime;
  final String soberTimeString;
  final bool isZero;
}

double _toFixed(double x, int digits) =>
    double.parse(x.toStringAsFixed(digits));

/// Blutalkoholkonzentration (‰) fuer die Drinks einer Person inkl. Resorption und Abbau.
BacResult calculateBacFromDrinks(
  List<Drink> userDrinks,
  BodyProfile? bodyProfile, {
  DateTime? currentTime,
}) {
  if (bodyProfile == null || bodyProfile.weightKg == 0 || userDrinks.isEmpty) {
    return const BacResult();
  }

  final tbw = calculateTbw(
    gender: bodyProfile.gender,
    age: bodyProfile.age,
    heightCm: bodyProfile.heightCm,
    weightKg: bodyProfile.weightKg,
  );
  if (tbw <= 0) return const BacResult();

  final nowMs = (currentTime ?? DateTime.now()).millisecondsSinceEpoch;

  final sorted =
      userDrinks
          .map(
            (d) => (
              alcoholG: d.alcoholG,
              timeMs: d.createdAt.millisecondsSinceEpoch,
            ),
          )
          .where((d) => d.alcoholG > 0)
          .toList()
        ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

  if (sorted.isEmpty) return const BacResult();

  // 1 g Reinalkohol -> Blutanteil am Koerperwasser ca. 80 %.
  final bacPerGram = 0.8 / tbw;

  final startMs = sorted.first.timeMs;
  if (startMs > nowMs) return const BacResult();

  const minuteMs = 60 * 1000;
  // Minutengenaue Simulation vom ersten Drink bis jetzt (max. 3 Tage).
  final totalMinutes = ((nowMs - startMs) ~/ minuteMs).clamp(0, 60 * 24 * 3);

  var simBac = 0.0;
  var peakBac = 0.0;
  var peakMinuteIndex = 0;

  for (var m = 0; m <= totalMinutes; m++) {
    final minuteTimeMs = startMs + m * minuteMs;

    var gramsThisMinute = 0.0;
    for (final d in sorted) {
      if (d.timeMs <= minuteTimeMs) {
        final minutesSinceDrink = (minuteTimeMs - d.timeMs) / minuteMs;
        if (minutesSinceDrink < absorptionDurationMinutes) {
          gramsThisMinute += d.alcoholG / absorptionDurationMinutes;
        }
      }
    }

    simBac += gramsThisMinute * bacPerGram;

    if (simBac > 0) {
      simBac = (simBac - bacMetabolismPerMinute).clamp(0, double.infinity);
    }

    if (simBac > peakBac) {
      peakBac = simBac;
      peakMinuteIndex = m;
    }
  }

  final currentBac = _toFixed(simBac, 2);
  final peakBacRounded = _toFixed(peakBac, 2);
  final peakTime = DateTime.fromMillisecondsSinceEpoch(
    startMs + peakMinuteIndex * minuteMs,
  );

  DateTime? soberTime;
  var soberTimeString = '';
  if (currentBac > 0) {
    final minutesToZero = (currentBac / bacMetabolismPerMinute).ceil();
    soberTime = DateTime.fromMillisecondsSinceEpoch(
      nowMs + minutesToZero * minuteMs,
    );
    final hh = soberTime.hour.toString().padLeft(2, '0');
    final mm = soberTime.minute.toString().padLeft(2, '0');
    soberTimeString = '$hh:$mm Uhr';
  }

  return BacResult(
    currentBac: currentBac,
    formattedBac: '~${currentBac.toStringAsFixed(2).replaceFirst('.', ',')} ‰',
    peakBac: peakBacRounded,
    peakTime: peakTime,
    soberTime: soberTime,
    soberTimeString: soberTimeString,
    isZero: currentBac <= 0,
  );
}
