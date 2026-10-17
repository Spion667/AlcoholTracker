import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/body_profile.dart';
import '../state/body_profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_sheet.dart';
import 'common.dart';

/// Promille-Radar: Koerperdaten (100 % lokal) erfassen, aendern oder loeschen.
Future<void> showBodyMetricsSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    maxHeightFactor: 0.9,
    builder: (ctx) => const _BodyMetricsSheet(),
  );
}

class _BodyMetricsSheet extends StatefulWidget {
  const _BodyMetricsSheet();

  @override
  State<_BodyMetricsSheet> createState() => _BodyMetricsSheetState();
}

class _BodyMetricsSheetState extends State<_BodyMetricsSheet> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  String _gender = 'male';
  bool _share = false;
  bool _hasExisting = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<BodyProfileController>().profile;
    _hasExisting = existing != null;
    _gender = existing?.gender ?? 'male';
    _share = existing?.shareInParty ?? false;
    _age = TextEditingController(text: '${existing?.age ?? 25}');
    _height = TextEditingController(text: '${existing?.heightCm ?? 175}');
    _weight = TextEditingController(text: '${existing?.weightKg ?? 70}');
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = context.read<BodyProfileController>();
    await controller.save(
      gender: _gender,
      age: num.tryParse(_age.text) ?? 25,
      heightCm: num.tryParse(_height.text) ?? 175,
      weightKg: num.tryParse(_weight.text) ?? 70,
      shareInParty: _share,
    );
    if (!mounted) return;
    setState(() => _saved = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    final controller = context.read<BodyProfileController>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Körperdaten löschen?', style: AppText.display(24)),
        content: Text(
          'Möchtest du deine hinterlegten Körperdaten wirklich rückstandslos von diesem Gerät löschen?',
          style: AppText.body(13, color: AppColors.dim, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Abbrechen',
              style: AppText.body(
                13,
                color: AppColors.dim,
                weight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Löschen',
              style: AppText.body(
                13,
                color: AppColors.pink,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.clear();
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Promille-Radar',
      titleSize: 24,
      titleBuilder: Row(
        spacing: 8,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.cyan.o(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 16,
              color: AppColors.cyan,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Promille-Radar', style: AppText.display(24)),
              Text(
                'Wissenschaftliche Watson-Schätzung',
                style: AppText.body(10, color: AppColors.faint),
              ),
            ],
          ),
        ],
      ),
      bodyPadding: const EdgeInsets.symmetric(vertical: 16),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // Datenschutz-Garantie
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: white(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: white(0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: AppColors.lime,
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppText.body(
                        11,
                        color: AppColors.dim,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: '100% Datenschutz:',
                          style: AppText.body(11, weight: FontWeight.w700),
                        ),
                        const TextSpan(
                          text:
                              ' Deine biometrischen Angaben (Gewicht, Größe etc.) werden ausschließlich '
                              'lokal auf diesem Smartphone gespeichert und niemals an Server oder Dritte übertragen.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel(
                'Biologisches Geschlecht (Körperwasser-Berechnung)',
                bottom: 6,
              ),
              Row(
                spacing: 8,
                children: [
                  for (final (id, label, icon) in genderOptions)
                    Expanded(
                      child: Pressable(
                        onTap: () => setState(() => _gender = id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _gender == id
                                ? AppColors.cyan.o(0.15)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _gender == id
                                  ? AppColors.cyan
                                  : white(0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 6,
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 12)),
                              Text(
                                label,
                                style: AppText.body(
                                  12,
                                  color: _gender == id
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
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Expanded(child: _metric('Alter', _age, 'J.')),
              Expanded(child: _metric('Größe', _height, 'cm')),
              Expanded(child: _metric('Gewicht', _weight, 'kg')),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _share = !_share),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: white(0.05)),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          'Promillewert in der Party teilen',
                          style: AppText.body(12, weight: FontWeight.w700),
                        ),
                        Text(
                          'Nur die berechnete Zahl (z. B. ~0,8 ‰) wird für Freunde sichtbar, niemals deine biometrischen Daten.',
                          style: AppText.body(
                            10,
                            color: AppColors.dim,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeonSwitch(
                    value: _share,
                    onChanged: (v) => setState(() => _share = v),
                    activeColor: AppColors.lime,
                    knobColor: Colors.black,
                    width: 44,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              'Hinweis: Schätzwert nach Watson-Kinetik. Niemals als Rechtsgrundlage für Fahrtauglichkeit nutzen – am Steuer gilt immer 0,0 ‰!',
              textAlign: TextAlign.center,
              style: AppText.body(
                9.5,
                color: AppColors.faint,
                height: 1.4,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          Column(
            spacing: 8,
            children: [
              NeonButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _save,
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
                              weight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Körperdaten speichern & Pegel berechnen',
                        style: AppText.body(
                          12,
                          color: Colors.black,
                          weight: FontWeight.w800,
                        ),
                      ),
              ),
              if (_hasExisting)
                Pressable(
                  onTap: _clear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 6,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: AppColors.pink.o(0.7),
                        ),
                        Text(
                          'Körperdaten vom Gerät löschen',
                          style: AppText.body(
                            11,
                            color: AppColors.pink.o(0.7),
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, TextEditingController c, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, size: 10, bottom: 4),
        AppTextField(
          controller: c,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          focusColor: AppColors.cyan,
          fontSize: 14,
          radius: 12,
          padding: const EdgeInsets.fromLTRB(10, 10, 22, 10),
          suffixText: unit,
          maxLength: 3,
        ),
      ],
    );
  }
}
