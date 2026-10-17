import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/party.dart';
import '../services/api.dart';
import '../state/profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/drinks.dart';
import '../utils/symbols.dart';
import '../widgets/app_sheet.dart';
import '../widgets/common.dart';
import '../widgets/symbol_sheets.dart';

const _partyEmojis = [
  '🎉',
  '🍺',
  '🍻',
  '🍹',
  '🍾',
  '🌴',
  '🔥',
  '🕺',
  '💃',
  '🚀',
];

/// Startseite: laufende Partys, neue Party starten, Guide.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Party> _parties = const [];
  bool _loading = true;

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    try {
      final list = await _api.listActiveParties();
      if (mounted) setState(() => _parties = list);
    } catch (e) {
      debugPrint('Fehler beim Laden der Partys: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String partyId) async {
    await context.push('/p/$partyId');
    if (mounted) _fetch();
  }

  Future<void> _join(String partyId) async {
    final me = context.read<ProfileController>().profile!;
    try {
      await _api.joinParty(partyId, me.id);
    } catch (e) {
      debugPrint('Beitritt fehlgeschlagen: $e');
    }
    if (mounted) await _open(partyId);
  }

  Future<void> _onCardTap(Party p) async {
    final me = context.read<ProfileController>().profile!;
    final isMember = p.members.any((m) => m.id == me.id);
    if (isMember) return _open(p.id);

    if (p.isProtected) {
      final ok = await showSymbolKeypadSheet(
        context,
        targetCode: p.symbolCode!,
        partyName: p.name,
      );
      if (ok && mounted) await _join(p.id);
      return;
    }
    await _join(p.id);
  }

  Future<void> _openCreateSheet() async {
    final created = await showAppSheet<_CreatedParty>(
      context,
      builder: (ctx) => _CreatePartySheet(api: _api),
    );
    if (created == null || !mounted) return;

    if (created.symbolCode != null) {
      await showPartyCodeSheet(
        context,
        symbolCode: created.symbolCode!,
        partyName: created.party.name,
        isJustCreated: true,
      );
    }
    if (mounted) await _open(created.party.id);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<ProfileController>().profile;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.lime,
          backgroundColor: AppColors.surfaceLight,
          onRefresh: _fetch,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: [
              // Top Header
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: glow(AppColors.lime),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Alcohol'),
                              TextSpan(
                                text: 'Tracker',
                                style: TextStyle(color: AppColors.lime),
                              ),
                            ],
                          ),
                          style: AppText.display(30),
                        ),
                      ],
                    ),
                    Pressable(
                      onTap: () => context.push('/me'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: white(0.05)),
                        ),
                        child: Row(
                          spacing: 8,
                          children: [
                            Text(
                              me?.emoji ?? '',
                              style: const TextStyle(fontSize: 18),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                me?.name ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  12,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Banner / Start CTA
              _Banner(onStart: _openCreateSheet),
              const SizedBox(height: 24),

              // Laufende Partys
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Laufende Partys (${_parties.length})',
                      style: AppText.display(24),
                    ),
                    GestureDetector(
                      onTap: _fetch,
                      child: Text(
                        'Aktualisieren',
                        style: AppText.body(
                          12,
                          color: AppColors.lime,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'Partys laden...',
                      style: AppText.body(12, color: AppColors.dim),
                    ),
                  ),
                )
              else if (_parties.isEmpty)
                const _EmptyParties()
              else
                Column(
                  spacing: 12,
                  children: [
                    for (final p in _parties)
                      _PartyCard(
                        party: p,
                        myId: me?.id,
                        onTap: () => _onCardTap(p),
                      ),
                  ],
                ),

              // Guide-Teaser
              const SizedBox(height: 24),
              GlassCard(
                onTap: () => context.push('/guide'),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.lime.o(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lime.o(0.2)),
                      ),
                      child: const Text('💡', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Text(
                                "So funktioniert's",
                                style: AppText.body(
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Pill(
                                radius: 6,
                                background: AppColors.lime.o(0.10),
                                borderColor: AppColors.lime.o(0.2),
                                child: Text(
                                  'GUIDE',
                                  style: AppText.mono(
                                    10,
                                    color: AppColors.lime,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Erfahre alles über Partys, Runden & den Story-Rückblick',
                            style: AppText.body(12, color: AppColors.dim),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.dim,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: white(0.10)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF181828), Color(0xFF10101C), AppColors.bg],
        ),
        boxShadow: [
          BoxShadow(
            color: black(0.5),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.lime.o(0.16), AppColors.lime.o(0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  'GEMEINSAM TRINKEN',
                  style: AppText.body(
                    12,
                    color: AppColors.lime,
                    weight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                Text(
                  'Bereit für die nächste Runde?',
                  style: AppText.display(36),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    'Starte ein Event oder tritt einer laufenden Party deiner Freunde bei.',
                    style: AppText.body(12, color: AppColors.dim, height: 1.5),
                  ),
                ),
                const SizedBox(height: 4),
                NeonButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: onStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      const Icon(Icons.add_rounded, size: 22),
                      Text(
                        'Neue Party starten',
                        style: AppText.body(
                          14,
                          color: Colors.black,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ],
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

class _EmptyParties extends StatelessWidget {
  const _EmptyParties();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      borderColor: white(0.10),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          spacing: 8,
          children: [
            const Text('🍹', style: TextStyle(fontSize: 36)),
            Text(
              'Gerade läuft keine Party.',
              style: AppText.body(14, weight: FontWeight.w700),
            ),
            Text(
              'Erstelle jetzt eine, damit deine Freunde direkt beitreten können!',
              textAlign: TextAlign.center,
              style: AppText.body(12, color: AppColors.dim),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.party,
    required this.myId,
    required this.onTap,
  });

  final Party party;
  final String? myId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final members = party.members.map((m) => m.profile).toList();
    final isMember = members.any((m) => m.id == myId);
    final actionColor = isMember
        ? AppColors.lime
        : (party.isProtected ? AppColors.cyan : AppColors.lime);
    final action = isMember
        ? 'Öffnen'
        : (party.isProtected ? 'Entsperren 🔒' : 'Beitreten');

    return GlassCard(
      onTap: onTap,
      borderColor: isMember ? AppColors.lime.o(0.3) : white(0.08),
      color: isMember ? AppColors.surface.o(0.95) : null,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiTile(
                emoji: party.emoji,
                size: 48,
                radius: 16,
                background: AppColors.surfaceLight,
                borderColor: white(0.05),
                fontSize: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          party.name,
                          style: AppText.body(
                            16,
                            weight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        if (party.isProtected)
                          Pill(
                            radius: 99,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            background: AppColors.cyan.o(0.15),
                            borderColor: AppColors.cyan.o(0.25),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 10,
                                  color: AppColors.cyan,
                                ),
                                Text(
                                  'Code-geschützt',
                                  style: AppText.body(
                                    10,
                                    color: AppColors.cyan,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'noch ${formatTimeRemaining(party.endsAt)}',
                      style: AppText.mono(11, color: AppColors.faint),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  spacing: 4,
                  children: [
                    Text(
                      action,
                      style: AppText.body(
                        12,
                        color: actionColor,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.dim,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: white(0.04))),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 28,
                  width: members.isEmpty
                      ? 0
                      : 28.0 + 20.0 * (members.length.clamp(0, 6) - 1),
                  child: Stack(
                    children: [
                      for (var i = 0; i < members.length.clamp(0, 6); i++)
                        Positioned(
                          left: i * 20.0,
                          child: Tooltip(
                            message: members[i].name,
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                members[i].emoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.group_rounded,
                  size: 14,
                  color: AppColors.lime,
                ),
                const SizedBox(width: 6),
                Text(
                  '${members.length} Teilnehmer',
                  style: AppText.body(
                    12,
                    color: AppColors.dim,
                    weight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isMember)
                  Pill(
                    radius: 99,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    background: AppColors.lime.o(0.10),
                    borderColor: AppColors.lime.o(0.2),
                    child: Text(
                      'Dabei ✓',
                      style: AppText.body(
                        10,
                        color: AppColors.lime,
                        weight: FontWeight.w700,
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

class _CreatedParty {
  const _CreatedParty(this.party, this.symbolCode);
  final Party party;
  final String? symbolCode;
}

class _CreatePartySheet extends StatefulWidget {
  const _CreatePartySheet({required this.api});

  final Api api;

  @override
  State<_CreatePartySheet> createState() => _CreatePartySheetState();
}

class _CreatePartySheetState extends State<_CreatePartySheet> {
  final _name = TextEditingController();
  String _emoji = '🎉';
  bool _protect = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSubmit => _name.text.trim().isNotEmpty && !_creating;

  Future<void> _create() async {
    if (!_canSubmit) return;
    setState(() => _creating = true);
    final me = context.read<ProfileController>().profile!;
    try {
      final code = _protect ? generateRandomSymbolCode() : null;
      final party = await widget.api.createParty(
        name: _name.text.trim(),
        emoji: _emoji,
        hostId: me.id,
        symbolCode: code,
      );
      if (mounted) Navigator.of(context).pop(_CreatedParty(party, code));
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        showToast(context, 'Fehler beim Erstellen: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Party starten',
      titleSize: 30,
      bodyPadding: const EdgeInsets.only(top: 12, bottom: 12),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('Party-Emoji', size: 12, bottom: 6),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.45,
                children: [
                  for (final em in _partyEmojis)
                    Pressable(
                      onTap: () => setState(() => _emoji = em),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _emoji == em
                              ? AppColors.lime.o(0.10)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _emoji == em ? AppColors.lime : white(0.05),
                          ),
                        ),
                        child: Text(em, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('Name der Party', size: 12, bottom: 4),
              AppTextField(
                controller: _name,
                hint: 'z.B. Geburtstagsfeier, WG-Abend...',
                maxLength: 40,
                fontSize: 14,
                padding: const EdgeInsets.all(14),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _create(),
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _protect = !_protect),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: white(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.o(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyan.o(0.2)),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mit Zufalls-Code schützen',
                          style: AppText.body(12, weight: FontWeight.w700),
                        ),
                        Text(
                          'Andere benötigen eine PIN, um beizutreten',
                          style: AppText.body(10, color: AppColors.dim),
                        ),
                      ],
                    ),
                  ),
                  NeonSwitch(
                    value: _protect,
                    onChanged: (v) => setState(() => _protect = v),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: white(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: white(0.05)),
            ),
            child: Text.rich(
              TextSpan(
                style: AppText.body(11, color: AppColors.faint, height: 1.5),
                children: [
                  const TextSpan(text: '⏰ '),
                  TextSpan(
                    text: 'Automatisches Ende:',
                    style: AppText.body(
                      11,
                      color: AppColors.faint,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' Die Party endet nach maximal 10 Stunden bzw. am nächsten Morgen um 10:00 Uhr. '
                        'Danach erhalten alle den Story-Rückblick des Abends!',
                  ),
                ],
              ),
            ),
          ),
          NeonButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: _canSubmit ? _create : null,
            child: Text(
              _creating ? 'Erstelle...' : 'Party jetzt eröffnen 🎉',
              style: AppText.body(
                14,
                color: Colors.black,
                weight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
