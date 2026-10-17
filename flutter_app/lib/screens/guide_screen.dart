import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _Point {
  const _Point(this.heading, this.desc);
  final String heading;
  final String desc;
}

class _Step {
  const _Step({
    required this.id,
    required this.number,
    required this.badge,
    required this.title,
    required this.icon,
    required this.color,
    required this.summary,
    required this.points,
    required this.preview,
  });

  final String id;
  final String number;
  final String badge;
  final String title;
  final IconData icon;
  final Color color;
  final String summary;
  final List<_Point> points;
  final Widget Function() preview;
}

Widget _previewBox(Widget child, {Gradient? gradient, Color? border}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.surfaceLight : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? white(0.05)),
      ),
      child: child,
    );

final _steps = <_Step>[
  _Step(
    id: 'party',
    number: '01',
    badge: 'Start & Beitritt',
    title: 'Party starten oder beitreten',
    icon: Icons.group_rounded,
    color: AppColors.lime,
    summary: 'Null Registrierung, keine Passwörter. Sofort loslegen.',
    points: const [
      _Point(
        'In 3 Sekunden eröffnet',
        'Tippe auf dem Homescreen auf „Neue Party starten“, vergib einen Namen und ein Party-Emoji.',
      ),
      _Point(
        'Alle Freunde sehen das Event live',
        'Deine Freunde öffnen einfach die App und sehen die laufende Party direkt auf dem Homescreen. Ein Klick auf „Beitreten“ genügt!',
      ),
      _Point(
        'Gäste ohne Smartphone mitnehmen',
        'Akku leer oder kein Handy dabei? Kein Problem: Über das Party-Menü kann der Host jederzeit Offline-Gäste hinzufügen und für sie mittracken.',
      ),
    ],
    preview: () => _previewBox(
      Column(
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 8,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 20)),
                  Text(
                    'WG-Abend',
                    style: AppText.body(12, weight: FontWeight.w700),
                  ),
                ],
              ),
              Pill(
                radius: 99,
                background: AppColors.lime.o(0.10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  'LIVE',
                  style: AppText.mono(
                    10,
                    color: AppColors.lime,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Text(
              '4 Teilnehmer • Host: Hannes',
              style: AppText.body(11, color: AppColors.dim),
            ),
          ),
        ],
      ),
    ),
  ),
  _Step(
    id: 'drinks',
    number: '02',
    badge: '1-Tap & Runden',
    title: 'Drinks & Runden tracken',
    icon: Icons.sports_bar_rounded,
    color: AppColors.amber,
    summary: 'Schnell, flexibel und mit 5-Sekunden-Rückgängig-Funktion.',
    points: const [
      _Point(
        '1-Tap Schnellauswahl',
        'Kategorisierte Liste: Bier (0.5L & 0.33L), Radler, Shots (Klopfer, Hubertus, Berentzen, Wodka) und Wein/Prosecco mit einem Fingertipp eintragen.',
      ),
      _Point(
        'Mischen-Konfigurator',
        'Stelle dein individuelles Mischverhältnis flexibel ein (z.B. 4cl Spirituose auf 200ml Softdrink). Die Gramm Reinalkohol werden exakt berechnet.',
      ),
      _Point(
        'Runden für die Gruppe ausgeben',
        'Du holst Bier an der Bar? Wähle einfach alle Freunde an und trage die Runde mit einem Klick für die ganze Truppe ein.',
      ),
      _Point(
        'Vergessen? Nachtragen ohne Reue',
        'Du hast vorhin vergessen zu tracken? Wähle im Menü einfach „Vor 30 Min“ oder „Vor 1 Std“, damit der zeitliche Verlauf exakt stimmt.',
      ),
      _Point(
        '5 Sekunden Rückgängig (Undo)',
        'Aus Versehen vertippt? Direkt nach jedem Eintrag erscheint 5 Sekunden lang ein praktischer Undo-Button.',
      ),
    ],
    preview: () => _previewBox(
      Column(
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCHNELLAUSWAHL & NACHTRAGEN',
                style: AppText.label(size: 10),
              ),
              Text(
                '1-Tap',
                style: AppText.body(
                  11,
                  color: AppColors.lime,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              for (final (icon, name, abv) in const [
                ('🍺', 'Bier 0.5L', '5.0% Vol.'),
                ('🥃', 'Wodka Shot', '40.0% Vol.'),
              ])
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: white(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: white(0.05)),
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 18)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppText.body(11, weight: FontWeight.w700),
                            ),
                            Text(
                              abv,
                              style: AppText.body(10, color: AppColors.dim),
                            ),
                          ],
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
  _Step(
    id: 'ranking',
    number: '03',
    badge: 'Fair & Gamified',
    title: 'Faires Live-Ranking & Badges',
    icon: Icons.emoji_events_rounded,
    color: AppColors.pink,
    summary: 'Vergleich nach reinem Alkohol (Gramm), dynamische Titel & Gruppen-Ziele.',
    points: const [
      _Point(
        'Wissenschaftlich fair berechnet',
        'Ein Shot und ein großes Bier sind nicht dasselbe. Die App berechnet den exakten Reinalkohol: Volumen (ml) × Vol.-% × 0.8 / 100.',
      ),
      _Point(
        'Dynamische Live-Titel (Badges)',
        'Wandern im Laufe des Abends: 👑 Bierkönig, ⚡ Shot-Maschine, 🤝 Spendierhose und 🚀 Frühstarter belohnen Aktivität sofort!',
      ),
      _Point(
        'Kollektive Gruppen-Meilensteine',
        'Oben im Leaderboard seht ihr den Gruppen-Fortschrittsbalken. Bei 25g, 50g oder 100g gibt es Live-Konfetti für alle im Raum!',
      ),
    ],
    preview: () => _previewBox(
      Column(
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 8,
                children: [
                  const Text('👑', style: TextStyle(fontSize: 16)),
                  Text(
                    '1. Lukas',
                    style: AppText.body(12, weight: FontWeight.w700),
                  ),
                ],
              ),
              Text(
                '48g Alkohol',
                style: AppText.mono(
                  12,
                  color: AppColors.lime,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: white(0.05),
              borderRadius: BorderRadius.circular(99),
            ),
            clipBehavior: Clip.antiAlias,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.8,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.lime),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  _Step(
    id: 'feed',
    number: '04',
    badge: 'Interaktiv',
    title: 'Live-Feed & Reaktionen',
    icon: Icons.bolt_rounded,
    color: AppColors.cyan,
    summary: 'Sieh jeden Drink live und reagiere mit Emojis.',
    points: const [
      _Point(
        'Live-Aktivitätsstrom',
        'Jedes Getränk und jede Runde erscheint sofort im Feed aller Teilnehmer.',
      ),
      _Point(
        'Reaktionen verteilen',
        'Feiere deine Freunde oder reagiere auf legendäre Runden mit 🔥, 🍻, 😵, 🫡 oder 💧.',
      ),
      _Point(
        'Einträge löschen',
        'Jeder Teilnehmer kann seine eigenen Getränke sowie Runden, die er für andere eingetragen hat, jederzeit im Ranking löschen.',
      ),
    ],
    preview: () => _previewBox(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hannes hat Bier 0.5L getrunken',
                style: AppText.body(11, weight: FontWeight.w700),
              ),
              Text(
                'vor 2 Minuten',
                style: AppText.body(10, color: AppColors.faint),
              ),
            ],
          ),
          Row(
            spacing: 4,
            children: [
              for (final label in const ['🍻 3', '🔥 2'])
                Pill(
                  radius: 8,
                  background: white(0.05),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    ),
  ),
  _Step(
    id: 'wrapped',
    number: '05',
    badge: 'Der Morgen danach',
    title: 'Automatisches Ende & Story-Rückblick',
    icon: Icons.schedule_rounded,
    color: const Color(0xFFA855F7),
    summary: 'Kein manuelles Beenden. Statistiken wie bei Spotify Wrapped.',
    points: const [
      _Point(
        'Automatisches Ende um 10:00 Uhr',
        'Niemand muss ans Beenden denken: Jede Party schließt nach 10 Stunden bzw. am nächsten Morgen um 10:00 Uhr automatisch (oder vorzeitig durch den Host).',
      ),
      _Point(
        'Animierter Story-Rückblick',
        'Am nächsten Tag erhalten alle Teilnehmer einen animierten Story-Rückblick mit Musik-Festival-Vibe.',
      ),
      _Point(
        'Fun Facts & Siegertreppchen',
        'Erfahrt euren Gruppen-Gesamtkonsum, das beliebteste Getränk, die wildeste Peak-Uhrzeit, wer die Spendierhose anhatte und das offizielle Podium mit Konfetti!',
      ),
    ],
    preview: () => _previewBox(
      Column(
        spacing: 6,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 20)),
          Text(
            'Story-Rückblick bereit!',
            style: AppText.body(12, weight: FontWeight.w700),
          ),
          Text(
            '142g Gesamtalkohol • 18 Runden • Top-Drink: Bier',
            textAlign: TextAlign.center,
            style: AppText.body(10, color: AppColors.dim),
          ),
        ],
      ),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF581C87).o(0.3),
          const Color(0xFF831843).o(0.3),
        ],
      ),
      border: const Color(0xFFA855F7).o(0.2),
    ),
  ),
];

/// "So funktioniert's": 5-Schritte-Anleitung.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String _active = 'all';

  @override
  Widget build(BuildContext context) {
    final steps = _active == 'all'
        ? _steps
        : _steps.where((s) => s.id == _active).toList();

    Widget chip(String id, String label) {
      final active = _active == id;
      return Pressable(
        onTap: () => setState(() => _active = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.lime : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(99),
            border: active ? null : Border.all(color: white(0.05)),
            boxShadow: active ? glow(AppColors.lime) : null,
          ),
          child: Text(
            label,
            style: AppText.body(
              12,
              color: active ? Colors.black : AppColors.dim,
              weight: active ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: white(0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Pressable(
                    onTap: () => popOrHome(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        spacing: 6,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: AppColors.lime,
                          ),
                          Text(
                            'Zurück',
                            style: AppText.body(
                              12,
                              color: AppColors.dim,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Text(
                        'ANLEITUNG',
                        style: AppText.mono(
                          12,
                          color: AppColors.faint,
                        ).copyWith(letterSpacing: 1.8),
                      ),
                      Pulse(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.lime,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Hero
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                spacing: 12,
                children: [
                  Pill(
                    radius: 99,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    background: AppColors.lime.o(0.10),
                    borderColor: AppColors.lime.o(0.2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.lime,
                        ),
                        Text(
                          'SO FUNKTIONIERT DIE APP',
                          style: AppText.body(
                            12,
                            color: AppColors.lime,
                            weight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Gemeinsam tracken,\n'),
                        TextSpan(
                          text: 'ohne Excel-Feeling.',
                          style: TextStyle(color: AppColors.lime),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: AppText.display(36).copyWith(height: 1.05),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      'AlcoholTracker macht gemeinsame Abende mit Freunden spielerisch, transparent und fair. '
                      'Hier erfährst du alles, was du wissen musst.',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        12,
                        color: AppColors.dim,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter-Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 6,
                children: [
                  chip('all', 'Alle Schritte'),
                  for (final s in _steps) chip(s.id, s.badge),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Schritte
            Column(
              spacing: 24,
              children: [for (final step in steps) _StepCard(step: step)],
            ),

            // Pro-Tipp
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.lime.o(0.2)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceLight, AppColors.bg],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 20,
                        color: AppColors.lime,
                      ),
                      Expanded(
                        child: Text(
                          'Pro-Tipp: Promille-Radar einrichten',
                          style: AppText.body(14, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Hinterlege optional Geschlecht, Alter, Größe und Gewicht – die App schätzt damit deinen '
                    'Pegel und zeigt dir, wann du wieder bei 0,0 ‰ bist. Die Daten bleiben ausschließlich auf deinem Handy:',
                    style: AppText.body(12, color: AppColors.dim, height: 1.5),
                  ),
                  for (final (title, text) in const [
                    (
                      'Einrichten:',
                      'Profil → Promille-Radar oder der „+ Promille“-Chip im Ranking.',
                    ),
                    (
                      'Teilen (optional):',
                      'Auf Wunsch sehen Freunde nur den berechneten Wert, nie deine Körperdaten.',
                    ),
                  ])
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: white(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: white(0.05)),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: AppText.body(
                            12,
                            color: AppColors.faint,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: '$title ',
                              style: AppText.body(12, weight: FontWeight.w700),
                            ),
                            TextSpan(text: text),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            NeonButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: () => popOrHome(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(
                    "Alles klar, los geht's!",
                    style: AppText.body(
                      14,
                      color: Colors.black,
                      weight: FontWeight.w900,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.o(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: white(0.10)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -12,
            right: -8,
            child: Text(
              step.number,
              style: AppText.display(72, color: white(0.03)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Row(
                spacing: 12,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: step.color.o(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: step.color.o(0.19)),
                    ),
                    child: Icon(step.icon, size: 20, color: step.color),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCHRITT ${step.number} • ${step.badge}'
                              .toUpperCase(),
                          style: AppText.mono(
                            10,
                            color: step.color,
                            weight: FontWeight.w700,
                          ).copyWith(letterSpacing: 0.9),
                        ),
                        Text(
                          step.title,
                          style: AppText.body(
                            16,
                            weight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                step.summary,
                style: AppText.body(12, color: AppColors.dim, height: 1.5),
              ),
              step.preview(),
              Column(
                spacing: 10,
                children: [
                  for (final pt in step.points)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: step.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: AppText.body(
                                12,
                                color: AppColors.faint,
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(
                                  text: '${pt.heading}: ',
                                  style: AppText.body(
                                    12,
                                    weight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                TextSpan(text: pt.desc),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
