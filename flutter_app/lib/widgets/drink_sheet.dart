import 'package:flutter/material.dart';

import '../models/drink.dart';
import '../models/profile.dart';
import '../services/haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/drinks.dart';
import 'app_sheet.dart';
import 'common.dart';
import 'confetti.dart';

/// Ergebnis des Drink-Sheets: was fuer wen und wann eingetragen werden soll.
class DrinkSheetResult {
  const DrinkSheetResult({
    required this.profileIds,
    required this.drink,
    this.createdAt,
  });

  final List<String> profileIds;
  final DrinkInput drink;
  final DateTime? createdAt;

  bool get isRound => profileIds.length > 1;
}

Future<DrinkSheetResult?> showDrinkSheet(
  BuildContext context, {
  required List<Profile> members,
  required Profile currentProfile,
}) {
  return showAppSheet<DrinkSheetResult>(
    context,
    maxHeightFactor: 0.88,
    builder: (ctx) =>
        _DrinkSheet(members: members, currentProfile: currentProfile),
  );
}

enum _Mode { grid, mix, custom }

class _DrinkSheet extends StatefulWidget {
  const _DrinkSheet({required this.members, required this.currentProfile});

  final List<Profile> members;
  final Profile currentProfile;

  @override
  State<_DrinkSheet> createState() => _DrinkSheetState();
}

class _DrinkSheetState extends State<_DrinkSheet> {
  late List<String> _selected = [widget.currentProfile.id];
  _Mode _mode = _Mode.grid;

  // Mischen
  String _mixSpirit = 'vodka';
  String _mixRatio = '30-70';
  int _mixSize = 250;

  // Eigenes Getraenk
  final _customName = TextEditingController();
  final _customVolume = TextEditingController(text: '330');
  final _customAbv = TextEditingController(text: '5.0');
  final _customIcon = TextEditingController(text: '🍹');
  double _customBeerFactor = 0;

  // Nachtragen (Minuten)
  int _offsetMinutes = 0;

  @override
  void dispose() {
    _customName.dispose();
    _customVolume.dispose();
    _customAbv.dispose();
    _customIcon.dispose();
    super.dispose();
  }

  DateTime? get _createdAt => _offsetMinutes == 0
      ? null
      : DateTime.now().subtract(Duration(minutes: _offsetMinutes));

  bool get _isRound => _selected.length > 1;

  void _toggle(String id) {
    Haptics.tap();
    setState(() {
      if (_selected.contains(id)) {
        if (_selected.length == 1) return; // mindestens eine Person
        _selected = _selected.where((p) => p != id).toList();
      } else {
        _selected = [..._selected, id];
      }
    });
  }

  void _finish(DrinkInput drink) {
    Haptics.tap();
    Confetti.burst(
      context,
      particleCount: 28,
      spread: 60,
      originY: 0.85,
      colors: const [AppColors.lime, AppColors.pink, AppColors.purple],
    );
    Navigator.of(context).pop(
      DrinkSheetResult(
        profileIds: _selected,
        drink: drink,
        createdAt: _createdAt,
      ),
    );
  }

  void _tapTile(DrinkDef def) {
    if (def.isCustomMix) {
      setState(() => _mode = _Mode.mix);
      return;
    }
    _finish(
      DrinkInput(
        key: def.key,
        name: def.name,
        icon: def.icon,
        category: def.category,
        volume: def.volume,
        abv: def.defaultAbv,
        beerFactor: def.beerFactor,
      ),
    );
  }

  double get _mixEffectiveAbv {
    final spirit = spiritsDb[_mixSpirit]!;
    final ratio = mixRatios.firstWhere(
      (r) => r.value == _mixRatio,
      orElse: () => mixRatios[2],
    );
    return double.parse((spirit.abv * ratio.ratio).toStringAsFixed(1));
  }

  void _submitMix() {
    final spirit = spiritsDb[_mixSpirit]!;
    final ratio = mixRatios.firstWhere(
      (r) => r.value == _mixRatio,
      orElse: () => mixRatios[2],
    );
    _finish(
      DrinkInput(
        key: 'mischen',
        name: 'Mischen ${spirit.name} (${ratio.value})',
        icon: '🥤',
        category: 'mix',
        volume: _mixSize.toDouble(),
        abv: _mixEffectiveAbv,
      ),
    );
  }

  void _submitCustom() {
    if (_customName.text.trim().isEmpty) return;
    double parse(String s, double fallback) {
      final v = double.tryParse(s.replaceAll(',', '.'));
      return (v == null || v == 0) ? fallback : v;
    }

    _finish(
      DrinkInput(
        key: 'custom',
        name: _customName.text.trim(),
        icon: _customIcon.text.trim().isEmpty ? '🍹' : _customIcon.text.trim(),
        category: 'other',
        volume: parse(_customVolume.text, 300),
        abv: parse(_customAbv.text, 5),
        beerFactor: _customBeerFactor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      _Mode.mix => 'Mischen Konfigurieren',
      _Mode.custom => 'Eigenes Getränk',
      _Mode.grid => 'Getränk wählen',
    };

    return AppSheetScaffold(
      title: title,
      titleSize: 30,
      closeSize: 36,
      subtitle: _isRound
          ? 'Runde für ${_selected.length} Personen 🍻'
          : '1 Tap = sofort geloggt',
      bodyPadding: const EdgeInsets.symmetric(vertical: 16),
      pinned: Column(
        children: [
          _WhoRow(
            members: widget.members,
            me: widget.currentProfile,
            selected: _selected,
            onToggle: _toggle,
            onOnlyMe: () {
              Haptics.tap();
              setState(() => _selected = [widget.currentProfile.id]);
            },
            onAll: () {
              Haptics.tap();
              setState(
                () => _selected = widget.members.map((m) => m.id).toList(),
              );
            },
          ),
          const Hairline(),
          _TimeRow(
            offset: _offsetMinutes,
            onChanged: (v) {
              Haptics.tap();
              setState(() => _offsetMinutes = v);
            },
          ),
          const Hairline(),
        ],
      ),
      body: switch (_mode) {
        _Mode.grid => _grid(),
        _Mode.mix => _mix(),
        _Mode.custom => _custom(),
      },
    );
  }

  Widget _grid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        for (final (idx, section) in drinksSections.indexed)
          Container(
            padding: EdgeInsets.only(top: idx > 0 ? 16 : 0),
            decoration: idx > 0
                ? BoxDecoration(
                    border: Border(top: BorderSide(color: white(0.08))),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Text(section.icon, style: const TextStyle(fontSize: 12)),
                    Text(
                      section.title.toUpperCase(),
                      style: AppText.label(size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (section.id == 'mix')
                  Pressable(
                    onTap: () => setState(() => _mode = _Mode.mix),
                    scale: 0.98,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: white(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Text('🥤', style: TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mischen konfigurieren',
                                  style: AppText.body(
                                    12,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Wodka, Korn, Springer · Verhältnis & Glasgröße',
                                  style: AppText.body(10, color: AppColors.dim),
                                ),
                              ],
                            ),
                          ),
                          Pill(
                            radius: 12,
                            background: AppColors.lime.o(0.10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              'Öffnen →',
                              style: AppText.body(
                                11,
                                color: AppColors.lime,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.55,
                    children: [
                      for (final d in section.drinks)
                        Pressable(
                          onTap: () => _tapTile(d),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: white(0.06)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  d.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body(
                                          12,
                                          weight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${d.volume.round()}ml · ${_fmt(d.defaultAbv)}%',
                                        style: AppText.mono(
                                          10,
                                          color: AppColors.faint,
                                        ),
                                      ),
                                    ],
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
          ),
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: white(0.08))),
          ),
          child: Pressable(
            onTap: () => setState(() => _mode = _Mode.custom),
            scale: 0.98,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: white(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: white(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.lime,
                  ),
                  Text(
                    'Anderes / Eigenes Getränk eintragen',
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
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}.0' : '$v';

  Widget _choice({
    required bool active,
    required VoidCallback onTap,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(10),
    double radius = 12,
  }) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: padding,
        decoration: BoxDecoration(
          color: active ? AppColors.lime.o(0.10) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: active ? AppColors.lime : white(0.05)),
        ),
        child: child,
      ),
    );
  }

  Widget _mix() {
    final grams = calculateAlcoholGrams(_mixSize.toDouble(), _mixEffectiveAbv);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Spirituose', size: 12, bottom: 8),
            Row(
              spacing: 8,
              children: [
                for (final MapEntry(key: k, value: s) in spiritsDb.entries)
                  Expanded(
                    child: _choice(
                      active: _mixSpirit == k,
                      onTap: () => setState(() => _mixSpirit = k),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(s.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            s.name,
                            style: AppText.body(
                              12,
                              color: _mixSpirit == k
                                  ? Colors.white
                                  : AppColors.dim,
                              weight: _mixSpirit == k
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          Text(
                            '${_fmt(s.abv)}%'.replaceFirst('.0', ''),
                            style: AppText.body(10, color: AppColors.faint),
                          ),
                        ],
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
              'Mischungsverhältnis (Alkohol – Softdrink)',
              size: 12,
              bottom: 8,
            ),
            Column(
              spacing: 6,
              children: [
                for (final r in mixRatios)
                  _choice(
                    active: _mixRatio == r.value,
                    onTap: () => setState(() => _mixRatio = r.value),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.label,
                          style: AppText.body(
                            12,
                            color: _mixRatio == r.value
                                ? Colors.white
                                : AppColors.dim,
                            weight: _mixRatio == r.value
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        Text(
                          r.value,
                          style: AppText.mono(12, color: AppColors.faint),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Glasgröße (ml)', size: 12, bottom: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.1,
              children: [
                for (final sz in mixSizes)
                  _choice(
                    active: _mixSize == sz,
                    onTap: () => setState(() => _mixSize = sz),
                    child: Center(
                      child: Text(
                        '$sz ml',
                        style: AppText.body(
                          12,
                          color: _mixSize == sz ? Colors.white : AppColors.dim,
                          weight: _mixSize == sz
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: white(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: white(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reiner Alkohol pro Glas:',
                style: AppText.body(12, color: AppColors.dim),
              ),
              Text(
                '${grams.toString()} g',
                style: AppText.mono(
                  14,
                  color: AppColors.lime,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: SecondaryButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => setState(() => _mode = _Mode.grid),
                child: const Text('Zurück'),
              ),
            ),
            Expanded(
              child: NeonButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _submitMix,
                child: const Text('Mischen eintragen'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _custom() {
    Widget labeled(String label, Widget field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [FieldLabel(label, size: 12, bottom: 4), field],
    );

    const numKeyboard = TextInputType.numberWithOptions(decimal: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        labeled(
          'Name des Getränks',
          AppTextField(
            controller: _customName,
            hint: 'z.B. Cuba Libre, Gin Basil Smash...',
            fontSize: 14,
            radius: 12,
            padding: const EdgeInsets.all(12),
            autofocus: true,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Expanded(
              child: labeled(
                'Menge (ml)',
                AppTextField(
                  controller: _customVolume,
                  keyboardType: numKeyboard,
                  fontSize: 14,
                  radius: 12,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
            Expanded(
              child: labeled(
                'Alkohol (% Vol.)',
                AppTextField(
                  controller: _customAbv,
                  keyboardType: numKeyboard,
                  fontSize: 14,
                  radius: 12,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Expanded(
              child: labeled(
                'Emoji',
                AppTextField(
                  controller: _customIcon,
                  textAlign: TextAlign.center,
                  fontSize: 18,
                  radius: 12,
                  padding: const EdgeInsets.all(10),
                  maxLength: 4,
                ),
              ),
            ),
            Expanded(
              child: labeled(
                'Bierfaktor',
                Column(
                  spacing: 6,
                  children: [
                    for (final (v, label) in const [
                      (0.0, '0 (Kein Bier)'),
                      (0.5, '0.5 (Radler)'),
                      (1.0, '1.0 (Volles Bier)'),
                    ])
                      _choice(
                        active: _customBeerFactor == v,
                        onTap: () => setState(() => _customBeerFactor = v),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            label,
                            style: AppText.body(
                              11,
                              color: _customBeerFactor == v
                                  ? Colors.white
                                  : AppColors.dim,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
                onPressed: () => setState(() => _mode = _Mode.grid),
                child: const Text('Zurück'),
              ),
            ),
            Expanded(
              child: NeonButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _submitCustom,
                child: const Text('Eintragen'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WhoRow extends StatelessWidget {
  const _WhoRow({
    required this.members,
    required this.me,
    required this.selected,
    required this.onToggle,
    required this.onOnlyMe,
    required this.onAll,
  });

  final List<Profile> members;
  final Profile me;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onOnlyMe;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FÜR WEN?', style: AppText.label()),
              Row(
                spacing: 8,
                children: [
                  GestureDetector(
                    onTap: onOnlyMe,
                    child: Text(
                      'Nur ich',
                      style: AppText.body(
                        11,
                        color: AppColors.lime,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (members.length > 1) ...[
                    Text('·', style: AppText.body(11, color: white(0.2))),
                    GestureDetector(
                      onTap: onAll,
                      child: Text(
                        'Runde für alle (${members.length})',
                        style: AppText.body(
                          11,
                          color: AppColors.pink,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              spacing: 8,
              children: [
                for (final m in members)
                  Pressable(
                    onTap: () => onToggle(m.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected.contains(m.id)
                            ? AppColors.lime.o(0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected.contains(m.id)
                              ? AppColors.lime
                              : white(0.05),
                        ),
                        boxShadow: selected.contains(m.id)
                            ? glow(AppColors.lime)
                            : null,
                      ),
                      child: Row(
                        spacing: 6,
                        children: [
                          Text(m.emoji, style: const TextStyle(fontSize: 16)),
                          Text(
                            m.id == me.id ? 'Du' : m.name,
                            style: AppText.body(
                              12,
                              color: selected.contains(m.id)
                                  ? Colors.white
                                  : AppColors.dim,
                              weight: FontWeight.w600,
                            ),
                          ),
                          if (selected.contains(m.id))
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.lime,
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
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.offset, required this.onChanged});

  final int offset;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 6,
            children: [
              Text('ZEITPUNKT', style: AppText.label()),
              if (offset > 0)
                Pill(
                  background: AppColors.pink.o(0.15),
                  borderColor: AppColors.pink.o(0.2),
                  child: Text(
                    'Nachtragen',
                    style: AppText.mono(
                      10,
                      color: AppColors.pink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: white(0.05)),
            ),
            child: Row(
              spacing: 4,
              children: [
                for (final (id, label) in const [
                  (0, 'Jetzt ⚡'),
                  (30, 'Vor 30 Min'),
                  (60, 'Vor 1 Std'),
                ])
                  Pressable(
                    onTap: () => onChanged(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: offset == id
                            ? AppColors.lime
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: AppText.body(
                          11,
                          color: offset == id ? Colors.black : AppColors.dim,
                          weight: offset == id
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
