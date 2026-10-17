import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../config/env.dart';
import '../models/party.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_sheet.dart';
import 'common.dart';

const _guestEmojis = [
  '👨',
  '👩',
  '👦',
  '👧',
  '🧔',
  '👱',
  '🦊',
  '🐻',
  '🐼',
  '🐸',
];

/// Teilt die Party per System-Share-Sheet (mit Link, falls `WEB_BASE_URL` gesetzt ist).
Future<void> shareParty(BuildContext context, Party party) async {
  final link = Env.partyLink(party.id);
  final text = StringBuffer(
    'Tritt der Party „${party.name}“ bei und tracke deine Drinks!',
  );
  if (link != null) text.write('\n$link');
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text.toString(),
        subject: 'AlcoholTracker: ${party.name}',
      ),
    );
  } catch (e) {
    if (context.mounted) {
      showToast(context, 'Teilen nicht möglich: $e', error: true);
    }
  }
}

Future<void> showPartyMenuSheet(
  BuildContext context, {
  required Party party,
  required bool isHost,
  required Future<void> Function({
    required String name,
    required String emoji,
    required String color,
  })
  onAddGuest,
  required Future<void> Function() onEndParty,
  required VoidCallback onShowCode,
  required VoidCallback onOpenBodyMetrics,
}) {
  return showAppSheet<void>(
    context,
    builder: (ctx) => _PartyMenu(
      party: party,
      isHost: isHost,
      onAddGuest: onAddGuest,
      onEndParty: onEndParty,
      onShowCode: onShowCode,
      onOpenBodyMetrics: onOpenBodyMetrics,
    ),
  );
}

enum _MenuMode { menu, addGuest, confirmEnd }

class _PartyMenu extends StatefulWidget {
  const _PartyMenu({
    required this.party,
    required this.isHost,
    required this.onAddGuest,
    required this.onEndParty,
    required this.onShowCode,
    required this.onOpenBodyMetrics,
  });

  final Party party;
  final bool isHost;
  final Future<void> Function({
    required String name,
    required String emoji,
    required String color,
  })
  onAddGuest;
  final Future<void> Function() onEndParty;
  final VoidCallback onShowCode;
  final VoidCallback onOpenBodyMetrics;

  @override
  State<_PartyMenu> createState() => _PartyMenuState();
}

class _PartyMenuState extends State<_PartyMenu> {
  _MenuMode _mode = _MenuMode.menu;
  final _guestName = TextEditingController();
  String _guestEmoji = '👤';

  @override
  void dispose() {
    _guestName.dispose();
    super.dispose();
  }

  void _closeThen(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Party-Optionen',
      titleSize: 24,
      bodyPadding: const EdgeInsets.symmetric(vertical: 16),
      body: switch (_mode) {
        _MenuMode.menu => _menu(),
        _MenuMode.addGuest => _guestForm(),
        _MenuMode.confirmEnd => _confirmEnd(),
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? borderColor,
    Color? background,
    Color? titleColor,
    Color? subtitleColor,
    Widget? badge,
  }) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background ?? AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? white(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.o(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppText.body(
                            14,
                            color: titleColor ?? Colors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ?badge,
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppText.body(
                      12,
                      color: subtitleColor ?? AppColors.dim,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu() {
    return Column(
      spacing: 10,
      children: [
        _menuItem(
          icon: Icons.share_rounded,
          color: AppColors.cyan,
          title: 'Party-Link teilen',
          subtitle: 'Lade Freunde mit einem Link ein',
          onTap: () => shareParty(context, widget.party),
        ),
        if (widget.party.isProtected)
          _menuItem(
            icon: Icons.lock_rounded,
            color: AppColors.lime,
            title: 'Party-Code anzeigen',
            subtitle: '4-teiligen PIN-Code für Freunde ansehen',
            borderColor: AppColors.lime.o(0.2),
            onTap: () => _closeThen(widget.onShowCode),
          ),
        _menuItem(
          icon: Icons.lock_rounded,
          color: AppColors.cyan,
          title: 'Promille-Radar',
          subtitle: 'Körperdaten für Pegel-Berechnung',
          badge: Pill(
            background: AppColors.cyan.o(0.2),
            child: Text(
              'PRIVAT',
              style: AppText.mono(
                10,
                color: AppColors.cyan,
                weight: FontWeight.w700,
              ),
            ),
          ),
          onTap: () => _closeThen(widget.onOpenBodyMetrics),
        ),
        _menuItem(
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.purple,
          title: 'Gast ohne Handy hinzufügen',
          subtitle: 'Trage jemanden ein, der selbst kein Handy hat',
          onTap: () => setState(() => _mode = _MenuMode.addGuest),
        ),
        if (widget.isHost) ...[
          const SizedBox(height: 6),
          _menuItem(
            icon: Icons.flag_rounded,
            color: const Color(0xFFF87171),
            title: 'Abend / Party jetzt beenden',
            subtitle: 'Schaltet den Story-Rückblick für alle frei',
            background: const Color(0xFFEF4444).o(0.10),
            borderColor: const Color(0xFFEF4444).o(0.2),
            titleColor: const Color(0xFFF87171),
            subtitleColor: const Color(0xFFFCA5A5).o(0.7),
            onTap: () => setState(() => _mode = _MenuMode.confirmEnd),
          ),
        ],
      ],
    );
  }

  Widget _guestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Avatar wählen', size: 12, bottom: 8),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                for (final em in _guestEmojis)
                  Pressable(
                    onTap: () => setState(() => _guestEmoji = em),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _guestEmoji == em
                            ? AppColors.purple.o(0.2)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _guestEmoji == em
                              ? AppColors.purple
                              : white(0.05),
                        ),
                      ),
                      child: Text(em, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Name des Gastes', size: 12, bottom: 4),
            AppTextField(
              controller: _guestName,
              hint: 'z.B. Lukas',
              fontSize: 14,
              radius: 12,
              padding: const EdgeInsets.all(12),
              focusColor: AppColors.purple,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitGuest(),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: SecondaryButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => setState(() => _mode = _MenuMode.menu),
                child: Text(
                  'Zurück',
                  style: AppText.body(12, weight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              child: NeonButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _submitGuest,
                child: Text(
                  'Gast hinzufügen',
                  style: AppText.body(
                    12,
                    color: Colors.black,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _submitGuest() {
    final name = _guestName.text.trim();
    if (name.isEmpty) return;
    widget.onAddGuest(name: name, emoji: _guestEmoji, color: '#8B5CF6');
    Navigator.of(context).pop();
  }

  Widget _confirmEnd() {
    return Column(
      spacing: 16,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).o(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 28,
            color: Color(0xFFF87171),
          ),
        ),
        Column(
          children: [
            Text('Party wirklich beenden?', style: AppText.display(24)),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Das beendet die Party für alle Teilnehmer und startet sofort das Wrapped-Highlight!',
                textAlign: TextAlign.center,
                style: AppText.body(12, color: AppColors.dim, height: 1.4),
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: SecondaryButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => setState(() => _mode = _MenuMode.menu),
                child: Text(
                  'Abbrechen',
                  style: AppText.body(12, weight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              child: Pressable(
                onTap: () {
                  widget.onEndParty();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Ja, beenden 🎉',
                    style: AppText.body(12, weight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
