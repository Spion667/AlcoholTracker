import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/version.dart';
import '../models/party.dart';
import '../services/api.dart';
import '../state/body_profile_controller.dart';
import '../state/profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/body_metrics_sheet.dart';
import '../widgets/changelog_sheet.dart';
import '../widgets/common.dart';

const _emojiOptions = [
  '😎',
  '🥳',
  '🤠',
  '🍺',
  '🍸',
  '🦊',
  '🐻',
  '🐼',
  '🦁',
  '🐸',
  '👨‍🦱',
  '👩‍🦱',
];
const _colorOptions = ['#C6FF3D', '#FF2E93', '#8B5CF6', '#00F0FF', '#FFB800'];

/// Mein Profil, Promille-Radar und Party-Historie.
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  late final TextEditingController _name;
  late String _emoji;
  late String _color;
  List<Party> _past = const [];
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final me = context.read<ProfileController>().profile;
    _name = TextEditingController(text: me?.name ?? '');
    _emoji = me?.emoji ?? '😎';
    _color = me?.color ?? '#C6FF3D';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPast());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadPast() async {
    final me = context.read<ProfileController>().profile;
    try {
      final list = await context.read<Api>().listPastParties(me?.id);
      if (mounted) setState(() => _past = list);
    } catch (e) {
      debugPrint('Fehler beim Laden der Historie: $e');
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await context.read<ProfileController>().updateProfile(
        name: name,
        emoji: _emoji,
        color: _color,
      );
      if (!mounted) return;
      setState(() => _saved = true);
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(_color);
    final body = context.watch<BodyProfileController>().profile;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: white(0.08))),
              ),
              child: Row(
                spacing: 12,
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => popOrHome(context),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Mein '),
                        TextSpan(
                          text: 'Profil',
                          style: TextStyle(color: AppColors.lime),
                        ),
                      ],
                    ),
                    style: AppText.display(30),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profil-Einstellungen
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Row(
                    spacing: 16,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.o(0.09),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accent),
                        ),
                        child: Text(
                          _emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Name', bottom: 4),
                            AppTextField(
                              controller: _name,
                              fontSize: 14,
                              radius: 12,
                              padding: const EdgeInsets.all(10),
                              maxLength: 25,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _save(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Avatar', bottom: 6),
                      GridView.count(
                        crossAxisCount: 6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          for (final em in _emojiOptions)
                            Pressable(
                              onTap: () => setState(() => _emoji = em),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _emoji == em
                                      ? white(0.20)
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _emoji == em
                                        ? Colors.white
                                        : white(0.05),
                                  ),
                                ),
                                child: Text(
                                  em,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Farbe', bottom: 6),
                      Row(
                        spacing: 10,
                        children: [
                          for (final hex in _colorOptions)
                            Pressable(
                              onTap: () => setState(() => _color = hex),
                              child: AnimatedScale(
                                scale: _color == hex ? 1.1 : 1,
                                duration: const Duration(milliseconds: 150),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: hexToColor(hex),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _color == hex
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  NeonButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: _saving ? null : _save,
                    child: _saved
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.black,
                              ),
                              Text(
                                'Gespeichert!',
                                style: AppText.body(
                                  12,
                                  color: Colors.black,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Änderungen speichern',
                            style: AppText.body(
                              12,
                              color: Colors.black,
                              weight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Promille-Radar
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 12,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.cyan.o(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 20,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 6,
                              children: [
                                Text(
                                  'Promille-Radar',
                                  style: AppText.body(
                                    12,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Pill(
                                  background: AppColors.cyan.o(0.15),
                                  child: Text(
                                    '100% PRIVAT',
                                    style: AppText.mono(
                                      10,
                                      color: AppColors.cyan,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              body != null
                                  ? '${switch (body.gender) {
                                      'female' => '👩 Weiblich',
                                      'other' => '🧑 Divers',
                                      _ => '👨 Männlich',
                                    }} · ${body.age}J. · ${body.heightCm}cm · ${body.weightKg}kg'
                                  : 'Berechne deinen geschätzten Alkoholpegel & Nüchternzeit',
                              style: AppText.body(10, color: AppColors.dim),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Pressable(
                        onTap: () => showBodyMetricsSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.o(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            body != null ? 'Bearbeiten' : 'Einrichten',
                            style: AppText.body(
                              12,
                              color: AppColors.cyan,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (body != null)
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: white(0.05))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            spacing: 6,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: body.shareInParty
                                      ? AppColors.lime
                                      : white(0.2),
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  style: AppText.body(11, color: AppColors.dim),
                                  children: [
                                    const TextSpan(text: 'In Party teilen: '),
                                    TextSpan(
                                      text: body.shareInParty
                                          ? 'Aktiviert'
                                          : 'Deaktiviert (Privat)',
                                      style: AppText.body(
                                        11,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => showBodyMetricsSheet(context),
                            child: Text(
                              'Optionen',
                              style: AppText.body(
                                11,
                                color: AppColors.cyan,
                                weight: FontWeight.w700,
                              ).copyWith(decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Historie
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Deine Partys & Wrappeds',
                style: AppText.display(24),
              ),
            ),
            if (_past.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Noch keine vergangenen Partys erfasst.',
                    textAlign: TextAlign.center,
                    style: AppText.body(12, color: AppColors.dim),
                  ),
                ),
              )
            else
              Column(
                spacing: 10,
                children: [
                  for (final p in _past)
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () => context.push('/p/${p.id}/wrapped'),
                      child: Row(
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: AppText.body(
                                    12,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  formatDate(p.createdAt),
                                  style: AppText.mono(
                                    10,
                                    color: AppColors.faint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: AppColors.pink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Wrapped',
                            style: AppText.body(
                              12,
                              color: AppColors.pink,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.faint,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

            // Version & Changelog
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: white(0.05))),
              ),
              child: Column(
                spacing: 10,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppText.mono(11, color: AppColors.faint),
                      children: [
                        const TextSpan(text: 'AlcoholTracker '),
                        TextSpan(
                          text: 'v$appVersion',
                          style: AppText.mono(
                            11,
                            color: AppColors.dim,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: () => showChangelogSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: white(0.05)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: AppColors.cyan,
                          ),
                          Text(
                            'Was ist neu? (Changelog)',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
