import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/body_profile.dart';
import '../state/body_profile_controller.dart';
import '../state/profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

const _emojiOptions = [
  '😎', '🥳', '🤠', '🍺', '🍸', //
  '🦊', '🐻', '🐼', '🦁', '🐸',
  '👨‍🦱', '👩‍🦱', '👨', '👩', '🧑',
];

const _colorOptions = <(String, String)>[
  ('Lime', '#C6FF3D'),
  ('Pink', '#FF2E93'),
  ('Purple', '#8B5CF6'),
  ('Cyan', '#00F0FF'),
  ('Amber', '#FFB800'),
];

/// Erstmalige Einrichtung: Name, Emoji, Farbe (+ optionaler Promille-Radar).
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController(text: '25');
  final _height = TextEditingController(text: '175');
  final _weight = TextEditingController(text: '70');

  String _emoji = '😎';
  String _color = '#C6FF3D';
  bool _submitting = false;
  bool _showPromille = false;
  String _gender = 'male';

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  bool get _canSubmit => _name.text.trim().isNotEmpty && !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final profileController = context.read<ProfileController>();
    final bodyController = context.read<BodyProfileController>();
    try {
      await profileController.saveProfile(
        name: _name.text.trim(),
        emoji: _emoji,
        color: _color,
      );
      final weight = num.tryParse(_weight.text);
      if (_showPromille && weight != null && weight > 0) {
        await bodyController.save(
          gender: _gender,
          age: num.tryParse(_age.text) ?? 25,
          heightCm: num.tryParse(_height.text) ?? 175,
          weightKg: weight,
          shareInParty: false,
        );
      }
      // Der Router leitet nach dem Anlegen des Profils automatisch zur Startseite.
    } catch (e) {
      if (mounted) showToast(context, 'Fehler beim Speichern: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(_color);
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header + Live-Vorschau
                  Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Dein '),
                            TextSpan(
                              text: 'Profil',
                              style: TextStyle(color: AppColors.lime),
                            ),
                          ],
                        ),
                        style: AppText.display(48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wähle einen Namen und Style für deine Runden mit Freunden.',
                        textAlign: TextAlign.center,
                        style: AppText.body(12, color: AppColors.dim),
                      ),
                      const SizedBox(height: 24),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.o(0.09),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: accent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accent.o(0.33),
                              blurRadius: 25,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Text(
                          _emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _name.text.trim().isEmpty
                            ? 'Dein Name'
                            : _name.text.trim(),
                        style: AppText.body(16, weight: FontWeight.w700),
                      ),
                    ],
                  ),

                  // Formular
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 24,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Dein Name', size: 12, bottom: 8),
                            AppTextField(
                              controller: _name,
                              hint: 'z.B. Alex, Tom, Lisa...',
                              maxLength: 25,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel(
                              'Emoji wählen',
                              size: 12,
                              bottom: 8,
                            ),
                            GridView.count(
                              crossAxisCount: 5,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.25,
                              children: [
                                for (final em in _emojiOptions)
                                  Pressable(
                                    onTap: () => setState(() => _emoji = em),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _emoji == em
                                            ? white(0.20)
                                            : AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _emoji == em
                                              ? Colors.white
                                              : white(0.05),
                                        ),
                                      ),
                                      child: Text(
                                        em,
                                        style: const TextStyle(fontSize: 24),
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
                            const FieldLabel(
                              'Deine Akzentfarbe',
                              size: 12,
                              bottom: 8,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 12,
                              children: [
                                for (final (_, hex) in _colorOptions)
                                  Pressable(
                                    onTap: () => setState(() => _color = hex),
                                    child: AnimatedScale(
                                      scale: _color == hex ? 1.1 : 1,
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: hexToColor(hex),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                        _PromilleNudge(
                          expanded: _showPromille,
                          onToggle: () =>
                              setState(() => _showPromille = !_showPromille),
                          gender: _gender,
                          onGender: (g) => setState(() => _gender = g),
                          age: _age,
                          height: _height,
                          weight: _weight,
                        ),
                        NeonButton(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: _canSubmit ? _submit : null,
                          child: Text(
                            _submitting ? 'Speichere...' : "Los geht's 🚀",
                            style: AppText.body(
                              16,
                              color: Colors.black,
                              weight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Kein Passwort nötig · Gespeichert auf deinem Gerät',
                      style: AppText.body(11, color: AppColors.faint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sanfter Nudge zum optionalen Promille-Radar im Onboarding.
class _PromilleNudge extends StatelessWidget {
  const _PromilleNudge({
    required this.expanded,
    required this.onToggle,
    required this.gender,
    required this.onGender,
    required this.age,
    required this.height,
    required this.weight,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final String gender;
  final ValueChanged<String> onGender;
  final TextEditingController age, height, weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: white(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Pressable(
            onTap: onToggle,
            scale: 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            Text(
                              'Promille-Schätzung',
                              style: AppText.body(12, weight: FontWeight.w700),
                            ),
                            Pill(
                              background: AppColors.cyan.o(0.15),
                              child: Text(
                                'Optional',
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
                          '100% privat & lokal auf deinem Handy',
                          style: AppText.body(10, color: AppColors.faint),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    expanded ? 'Einklappen' : 'Einrichten',
                    style: AppText.body(
                      12,
                      color: AppColors.cyan,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: white(0.05))),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel(
                              'Biologisches Geschlecht',
                              size: 10,
                              bottom: 4,
                            ),
                            Row(
                              spacing: 6,
                              children: [
                                for (final (id, label, icon) in genderOptions)
                                  Expanded(
                                    child: Pressable(
                                      onTap: () => onGender(id),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: gender == id
                                              ? AppColors.cyan.o(0.2)
                                              : black(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: gender == id
                                                ? AppColors.cyan
                                                : white(0.05),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 4,
                                          children: [
                                            Text(
                                              icon,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              label,
                                              style: AppText.body(
                                                12,
                                                color: gender == id
                                                    ? Colors.white
                                                    : AppColors.dim,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: _NumberField(
                                label: 'Alter',
                                controller: age,
                              ),
                            ),
                            Expanded(
                              child: _NumberField(
                                label: 'Größe (cm)',
                                controller: height,
                              ),
                            ),
                            Expanded(
                              child: _NumberField(
                                label: 'Gewicht (kg)',
                                controller: weight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, size: 10, bottom: 4),
        AppTextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          focusColor: AppColors.cyan,
          fontSize: 12,
          radius: 12,
          padding: const EdgeInsets.all(8),
          fillColor: black(0.2),
          maxLength: 3,
        ),
      ],
    );
  }
}
