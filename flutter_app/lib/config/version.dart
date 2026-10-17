/// Versions-Konfiguration & Release-Historie (Spiegel von `src/config/version.js`).
const appVersion = '2.2.0';
const appReleaseDate = '11. Oktober 2026';
const appName = 'AlcoholTracker';

class Release {
  const Release({
    required this.version,
    required this.date,
    required this.title,
    required this.highlights,
    this.badge,
  });

  final String version;
  final String date;
  final String title;
  final String? badge;
  final List<String> highlights;
}

const releases = <Release>[
  Release(
    version: '2.2.0',
    date: '11.10.2026',
    title: 'Promille-Radar & Watson-Pegel-Kinetik',
    badge: 'Aktuell 🚀',
    highlights: [
      'Wissenschaftliche Promille-Schätzung nach anerkannter Watson-Formel (TBW)',
      '100% Datenschutz: Biometrische Körperdaten bleiben rein lokal auf deinem Smartphone',
      '2-Stufen-Discovery: Sanft im Onboarding & per 1-Tap Chip direkt auf der Leaderboard-Karte',
      'Ausnüchterungs-Prognose: Genaue Uhrzeit für 0,0 ‰ beim Aufklappen der eigenen Karte',
      'Freiwilliges Teilen: Opt-in Schalter, um den errechneten Pegel für Party-Freunde freizugeben',
    ],
  ),
  Release(
    version: '2.1.1',
    date: '11.10.2026',
    title: 'Fluid Club Aurora & iOS WebKit Blur Clearance',
    badge: 'Vorherig',
    highlights: [
      'Volle Raumausfüllung mit fließender Fluid Club Aurora über 100% Breite und Höhe',
      'Dynamische 97px Safe-Area Clearance: Gestochen scharfer Text unter iOS WebKit Blur',
      'Entfernung der störenden Querlinie für nahtlose Lichtatmosphäre',
      'Interaktive Wrapped-Buttons auf dem finalen Share-Slide gefixt',
    ],
  ),
  Release(
    version: '2.1.0',
    date: '11.10.2026',
    title: 'Party-PIN & Interaktives Keypad',
    highlights: [
      'Optionaler 4-Symbol PIN-Schutz (♠️ ♥️ ♦️ ♣️) für private Partys',
      'Interaktives Keypad mit Web-Audio Klick und Android-Vibration',
      'Party-Code jederzeit über Header [🔒 Code] einsehbar',
      'Automatischer Direktlink-Schutz für Nicht-Mitglieder',
    ],
  ),
  Release(
    version: '2.0.2',
    date: '10.10.2026',
    title: 'Social Incentives & Dynamic Badges',
    highlights: [
      'Dynamische Live-Titel: Bierkönig 👑, Shot-Maschine ⚡, Spendierhose 🤝, Frühstarter 🚀',
      'Kollektive Gruppen-Meilensteine mit Konfetti-Belohnung',
      'Verzeihendes Nachtragen: Zeit-Schnellauswahl im Drink-Sheet',
    ],
  ),
  Release(
    version: '2.0.1',
    date: '10.10.2026',
    title: 'Neues Branding & In-App Guide',
    highlights: [
      'Neues modernes App-Logo & PWA Icons',
      'Interaktiver 5-Schritte In-App Guide (/guide)',
      'Erste Safe-Area Optimierungen für iPhone Displays',
    ],
  ),
  Release(
    version: '2.0.0',
    date: '10.10.2026',
    title: 'AlcoholTracker 2.0 Club Edition',
    highlights: [
      'Komplettes Cyberpunk / Nightclub Neon-Redesign',
      'Realtime Partys mit Live-Ranking und Live-Feed',
      'Quick-Repeat Daumenzone für 1-Klick Drink-Erfassung',
      'Spotify-Wrapped Story Player am Ende der Party',
      'Volle PWA-Unterstützung für iOS & Android',
    ],
  ),
  Release(
    version: '1.0.0',
    date: '31.08.2026',
    title: 'Supabase Cloud Backend & Tavern Edition',
    highlights: [
      'Migration auf PostgreSQL Cloud-Backend via Supabase',
      'Multi-User Identity & Profilerstellung',
      'Tavern-Design & Freundeslisten-Verwaltung',
    ],
  ),
];
