import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/symbols.dart';
import 'app_sheet.dart';
import 'common.dart';
import 'confetti.dart';
import 'suit_icon.dart';

/// Symbol-Keypad (Wii-U-Style). Liefert `true`, wenn der Code korrekt eingegeben wurde.
Future<bool> showSymbolKeypadSheet(
  BuildContext context, {
  required String targetCode,
  String? partyName,
}) async {
  final result = await showAppSheet<bool>(
    context,
    maxHeightFactor: 0.9,
    borderColor: AppColors.cyan.o(0.2),
    builder: (ctx) =>
        _SymbolKeypad(targetCode: targetCode, partyName: partyName),
  );
  return result ?? false;
}

/// Zeigt den Party-Code als leuchtende Karten.
Future<void> showPartyCodeSheet(
  BuildContext context, {
  required String symbolCode,
  String? partyName,
  bool isJustCreated = false,
}) {
  final symbols = parseSymbolCode(symbolCode);
  if (symbols.length != 4) return Future.value();
  return showAppSheet<void>(
    context,
    borderColor: AppColors.cyan.o(0.3),
    shadows: [BoxShadow(color: AppColors.cyan.o(0.15), blurRadius: 40)],
    builder: (ctx) => _PartyCode(
      symbols: symbols,
      partyName: partyName,
      isJustCreated: isJustCreated,
    ),
  );
}

List<BoxShadow> _symbolGlow(Color c) => [
  BoxShadow(color: c.o(0.4), blurRadius: 15),
];

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.cyan.o(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cyan.o(0.2)),
        ),
        child: const Icon(Icons.lock_rounded, size: 16, color: AppColors.cyan),
      ),
      Text(title, style: AppText.display(24)),
    ],
  );
}

class _SymbolKeypad extends StatefulWidget {
  const _SymbolKeypad({required this.targetCode, this.partyName});

  final String targetCode;
  final String? partyName;

  @override
  State<_SymbolKeypad> createState() => _SymbolKeypadState();
}

class _SymbolKeypadState extends State<_SymbolKeypad>
    with SingleTickerProviderStateMixin {
  final _entered = <String>[];
  String _error = '';
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _tap(String id) {
    if (_entered.length >= 4) return;
    Haptics.tap();
    Haptics.click();
    setState(() {
      _error = '';
      _entered.add(id);
    });

    if (_entered.length == 4) {
      if (verifySymbolCode(_entered, widget.targetCode)) {
        Haptics.success();
        Confetti.burst(
          context,
          particleCount: 45,
          spread: 70,
          originY: 0.6,
          colors: const [
            AppColors.cyan,
            AppColors.pink,
            AppColors.amber,
            AppColors.lime,
          ],
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      } else {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          Haptics.error();
          setState(() => _error = 'Falsche Symbol-Kombination! Frag den Host.');
          _shake.forward(from: 0);
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(_entered.clear);
          });
        });
      }
    }
  }

  void _delete() {
    if (_entered.isEmpty) return;
    Haptics.tap();
    Haptics.click();
    setState(() {
      _error = '';
      _entered.removeLast();
    });
  }

  void _reset() {
    if (_entered.isEmpty) return;
    Haptics.tap();
    setState(() {
      _error = '';
      _entered.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Code eingeben',
      leading: null,
      onClose: () => Navigator.of(context).pop(false),
      titleBuilder: const _SheetTitle('Code eingeben'),
      body: Column(
        spacing: 20,
        children: [
          Column(
            children: [
              Text(
                widget.partyName ?? 'Party geschützt',
                style: AppText.body(16, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Gib die 4 Symbole in der richtigen Reihenfolge ein:',
                textAlign: TextAlign.center,
                style: AppText.body(12, color: AppColors.dim),
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Row(
                spacing: 12,
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: _Slot(
                        symbol: i < _entered.length
                            ? cardSymbolsMap[_entered[i]]
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_error.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.pink,
                ),
                Flexible(
                  child: Text(
                    _error,
                    style: AppText.body(
                      12,
                      color: AppColors.pink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                for (final s in cardSymbols)
                  Opacity(
                    opacity: _entered.length >= 4 ? 0.6 : 1,
                    child: Pressable(
                      onTap: _entered.length >= 4 ? null : () => _tap(s.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: s.color.o(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: s.color.o(0.4), width: 2),
                          boxShadow: _symbolGlow(s.color),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 12,
                          children: [
                            SuitIcon(id: s.id, color: s.color, size: 30),
                            Text(
                              s.label,
                              style: AppText.body(
                                16,
                                weight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              _ControlButton(
                onTap: _entered.isEmpty ? null : _delete,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Icon(Icons.backspace_outlined, size: 16),
                    Text('Letztes löschen'),
                  ],
                ),
              ),
              _ControlButton(
                onTap: _entered.isEmpty ? null : _reset,
                child: const Text('Zurücksetzen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({this.symbol});

  final CardSymbol? symbol;

  @override
  Widget build(BuildContext context) {
    final s = symbol;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: s == null ? white(0.02) : s.color.o(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: s == null ? white(0.10) : s.color.o(0.4),
            width: s == null ? 1 : 2,
          ),
          boxShadow: s == null ? null : _symbolGlow(s.color),
        ),
        alignment: Alignment.center,
        child: s == null
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: white(0.10),
                  shape: BoxShape.circle,
                ),
              )
            : SuitIcon(id: s.id, color: s.color, size: 32),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.3 : 1,
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: white(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: white(0.05)),
          ),
          child: DefaultTextStyle(
            style: AppText.body(12, color: AppColors.dim),
            child: IconTheme(
              data: const IconThemeData(color: AppColors.dim),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PartyCode extends StatelessWidget {
  const _PartyCode({
    required this.symbols,
    required this.partyName,
    required this.isJustCreated,
  });

  final List<CardSymbol> symbols;
  final String? partyName;
  final bool isJustCreated;

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Party-Code',
      titleBuilder: const _SheetTitle('Party-Code'),
      bodyPadding: const EdgeInsets.symmetric(vertical: 24),
      body: Column(
        spacing: 24,
        children: [
          Column(
            spacing: 8,
            children: [
              Pill(
                radius: 99,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                background: AppColors.pink.o(0.15),
                borderColor: AppColors.pink.o(0.2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppColors.pink,
                    ),
                    Text(
                      'PARTY-PIN',
                      style: AppText.body(
                        12,
                        color: AppColors.pink,
                        weight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isJustCreated
                    ? 'Party erfolgreich erstellt! 🎉'
                    : (partyName ?? 'Party-Code'),
                textAlign: TextAlign.center,
                style: AppText.body(18, weight: FontWeight.w800),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'Zeige diesen 4-Symbol-Code deinen Freunden im Raum, damit sie beitreten können:',
                  textAlign: TextAlign.center,
                  style: AppText.body(12, color: AppColors.dim, height: 1.4),
                ),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Row(
              spacing: 10,
              children: [
                for (final s in symbols)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: s.color.o(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: s.color.o(0.4), width: 2),
                          boxShadow: _symbolGlow(s.color),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SuitIcon(id: s.id, color: s.color, size: 30),
                            const SizedBox(height: 4),
                            Text(
                              s.label.toUpperCase(),
                              style: AppText.mono(
                                10,
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
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: white(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: white(0.05)),
              ),
              child: Text.rich(
                TextSpan(
                  style: AppText.body(11, color: AppColors.faint, height: 1.5),
                  children: [
                    const TextSpan(text: '💡 '),
                    TextSpan(
                      text: 'Tipp:',
                      style: AppText.body(
                        11,
                        color: AppColors.faint,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(
                      text: ' Du kannst diesen Code auch während der Party jederzeit oben über den ',
                    ),
                    TextSpan(
                      text: '[🔒 Code]',
                      style: AppText.body(
                        11,
                        color: AppColors.faint,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: '-Button im Header aufrufen.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: NeonButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isJustCreated ? 'Alles klar, zur Party 🚀' : 'Schließen'),
        ),
      ),
    );
  }
}
