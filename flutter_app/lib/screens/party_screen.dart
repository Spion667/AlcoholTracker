import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/drink.dart';
import '../models/party.dart';
import '../services/api.dart';
import '../services/haptics.dart';
import '../state/body_profile_controller.dart';
import '../state/party_controller.dart';
import '../state/profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/bac.dart';
import '../utils/drinks.dart';
import '../widgets/aurora.dart';
import '../widgets/body_metrics_sheet.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/drink_sheet.dart';
import '../widgets/feed.dart';
import '../widgets/leaderboard.dart';
import '../widgets/party_menu_sheet.dart';
import '../widgets/symbol_sheets.dart';
import '../widgets/undo_toast.dart';

enum _Tab { ranking, feed }

/// Party: Live-Ranking, Live-Feed und Drinks eintragen.
class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key, required this.partyId});

  final String partyId;

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> with WidgetsBindingObserver {
  late final PartyController _ctrl;
  late final BodyProfileController _body;
  Timer? _clock;

  _Tab _tab = _Tab.ranking;
  UndoInfo? _undo;

  int? _prevAchieved;
  bool _joining = false;
  bool _keypadShown = false;
  String _lastBacKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final me = context.read<ProfileController>().profile!;
    _ctrl =
        PartyController(
            partyId: widget.partyId,
            me: me,
            api: context.read<Api>(),
          )
          ..addListener(_onControllerChanged)
          ..init();
    _body = context.read<BodyProfileController>()..addListener(_syncBac);

    // Countdown, Zeitangaben und Promille alle 60 s auffrischen.
    _clock = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _body.removeListener(_syncBac);
    _ctrl
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Realtime-Events waehrend der Pause gehen verloren -> beim Zurueckkehren neu laden.
    if (state == AppLifecycleState.resumed) _ctrl.refresh();
  }

  void _onControllerChanged() {
    if (_ctrl.loading) return;

    // Gruppen-Meilenstein-Konfetti
    final achieved = getGroupMilestoneInfo(_ctrl.totalPartyAlcoholGrams)
        .achievedCount;
    if (_prevAchieved == null) {
      _prevAchieved = achieved;
    } else if (achieved > _prevAchieved!) {
      _prevAchieved = achieved;
      if (mounted) {
        Confetti.burst(
          context,
          particleCount: 75,
          spread: 90,
          originY: 0.55,
          colors: const [AppColors.lime, AppColors.pink, AppColors.amber],
        );
      }
    }

    // Offene Partys automatisch beitreten (Direktlink)
    final party = _ctrl.party;
    if (party != null && !_ctrl.isMember && !party.isProtected && !_joining) {
      _joining = true;
      _ctrl.join().catchError(
        (Object e) => debugPrint('Beitritt fehlgeschlagen: $e'),
      );
    }

    _syncBac();
  }

  /// Teilt (freiwillig) den berechneten Promillewert mit der Party.
  void _syncBac() {
    if (_ctrl.loading || !_ctrl.isMember) return;
    final body = _body.profile;
    final myDrinks = _ctrl.drinks
        .where((d) => d.profileId == _ctrl.me.id)
        .toList();
    final key =
        '${myDrinks.length}:${myDrinks.isEmpty ? '' : myDrinks.first.id}:'
        '${body?.shareInParty}:${body?.updatedAt?.millisecondsSinceEpoch}';
    if (key == _lastBacKey) return;
    _lastBacKey = key;

    if (body != null && body.shareInParty) {
      final bac = calculateBacFromDrinks(myDrinks, body);
      _ctrl.api.updateMemberBac(widget.partyId, _ctrl.me.id, bac.currentBac);
    } else {
      _ctrl.api.updateMemberBac(widget.partyId, _ctrl.me.id, null);
    }
  }

  Future<void> _log(DrinkSheetResult r) async {
    try {
      final logged = await _ctrl.logDrink(
        profileIds: r.profileIds,
        drink: r.drink,
        createdAt: r.createdAt,
      );
      if (logged.isNotEmpty && mounted) {
        setState(
          () => _undo = UndoInfo(
            drinkIds: logged.map((d) => d.id).toList(),
            name: r.drink.name,
            icon: r.drink.icon,
            isRound: r.isRound,
          ),
        );
      }
    } catch (e) {
      if (mounted) showToast(context, 'Fehler beim Eintragen: $e', error: true);
    }
  }

  Future<void> _openDrinkSheet() async {
    Haptics.tap();
    final result = await showDrinkSheet(
      context,
      members: _ctrl.members.map((m) => m.profile).toList(),
      currentProfile: _ctrl.me,
    );
    if (result != null) await _log(result);
  }

  Future<void> _quickRepeat(Drink last) async {
    Haptics.success();
    Confetti.burst(
      context,
      particleCount: 20,
      spread: 50,
      originY: 0.9,
      colors: const [AppColors.lime, AppColors.pink],
    );
    // Bierfaktor exakt aus dem Original ableiten (statt pauschal 1).
    final beerFactor = last.volumeMl > 0
        ? last.beerLiters * 1000 / last.volumeMl
        : 0.0;
    await _log(
      DrinkSheetResult(
        profileIds: [_ctrl.me.id],
        drink: DrinkInput(
          key: last.drinkKey,
          name: last.name,
          icon: last.icon,
          category: last.category,
          volume: last.volumeMl,
          abv: last.abv,
          beerFactor: beerFactor,
        ),
      ),
    );
  }

  Future<void> _undoLast() async {
    final undo = _undo;
    if (undo == null) return;
    setState(() => _undo = null);
    try {
      for (final id in undo.drinkIds) {
        await _ctrl.deleteDrink(id);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Rückgängig fehlgeschlagen: $e', error: true);
      }
    }
  }

  Future<void> _showCode() async {
    final party = _ctrl.party;
    if (party == null || !party.isProtected) return;
    await showPartyCodeSheet(
      context,
      symbolCode: party.symbolCode!,
      partyName: party.name,
    );
  }

  Future<void> _unlock() async {
    final party = _ctrl.party!;
    final ok = await showSymbolKeypadSheet(
      context,
      targetCode: party.symbolCode!,
      partyName: party.name,
    );
    if (!mounted) return;
    if (ok) {
      await _ctrl.join();
    } else {
      popOrHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_ctrl, _body]),
      builder: (context, _) {
        if (_ctrl.loading) return const LoadingView(label: 'Lade Party...');

        final party = _ctrl.party;
        if (party == null) {
          return _NotFound(onBack: () => popOrHome(context));
        }

        // Direktlink-Schutz fuer Partys mit Symbol-Code
        if (party.isProtected && !_ctrl.isMember) {
          if (!_keypadShown) {
            _keypadShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _unlock();
            });
          }
          return _LockedParty(
            name: party.name,
            onUnlock: _unlock,
            onBack: () => popOrHome(context),
          );
        }

        return _buildParty(context, party);
      },
    );
  }

  Widget _buildParty(BuildContext context, Party party) {
    final me = _ctrl.me;
    final isEnded = party.isEndedAt(DateTime.now());
    final last = _ctrl.lastDrinkOfUser;
    final members = _ctrl.members;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg.o(0.65),
                  border: Border(bottom: BorderSide(color: white(0.08))),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    const Positioned.fill(child: AuroraBackground()),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SquareIconButton(
                                  icon: Icons.arrow_back_rounded,
                                  onTap: () => popOrHome(context),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        spacing: 6,
                                        children: [
                                          Text(
                                            party.emoji,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              party.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.body(
                                                16,
                                                weight: FontWeight.w800,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          style:
                                              AppText.mono(
                                                11,
                                                color: AppColors.faint,
                                              ).copyWith(
                                                shadows: [
                                                  Shadow(
                                                    color: black(0.7),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${members.length} '
                                                  '${members.length == 1 ? 'Person' : 'Personen'} · ',
                                            ),
                                            if (isEnded)
                                              TextSpan(
                                                text: 'Party beendet',
                                                style: AppText.mono(
                                                  11,
                                                  color: AppColors.pink,
                                                  weight: FontWeight.w700,
                                                ),
                                              )
                                            else
                                              TextSpan(
                                                text:
                                                    'noch ${formatTimeRemaining(party.endsAt)}',
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  spacing: 8,
                                  children: [
                                    if (party.isProtected)
                                      Pressable(
                                        onTap: _showCode,
                                        child: Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceLight,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: AppColors.lime.o(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            spacing: 6,
                                            children: [
                                              const Icon(
                                                Icons.lock_rounded,
                                                size: 14,
                                                color: AppColors.lime,
                                              ),
                                              Text(
                                                'Code',
                                                style: AppText.body(
                                                  11,
                                                  color: AppColors.lime,
                                                  weight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (isEnded)
                                      Pulse(
                                        child: Pressable(
                                          onTap: () => context.push(
                                            '/p/${widget.partyId}/wrapped',
                                            extra: 'party',
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppColors.pink,
                                                  AppColors.purple,
                                                ],
                                              ),
                                              boxShadow: glow(AppColors.pink),
                                            ),
                                            child: Row(
                                              spacing: 4,
                                              children: [
                                                const Icon(
                                                  Icons.auto_awesome_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  'Wrapped',
                                                  style: AppText.body(
                                                    12,
                                                    weight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    SquareIconButton(
                                      icon: Icons.more_vert_rounded,
                                      onTap: () => showPartyMenuSheet(
                                        context,
                                        party: party,
                                        isHost: _ctrl.isHost,
                                        onAddGuest: _ctrl.addGuest,
                                        onEndParty: _ctrl.endParty,
                                        onShowCode: _showCode,
                                        onOpenBodyMetrics: () =>
                                            showBodyMetricsSheet(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _TabSwitcher(
                              tab: _tab,
                              feedCount: _ctrl.totalPartyDrinks,
                              onChanged: (t) => setState(() => _tab = t),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Inhalt
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.lime,
                  backgroundColor: AppColors.surfaceLight,
                  onRefresh: _ctrl.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                    children: [
                      if (_tab == _Tab.ranking)
                        Leaderboard(
                          leaderboard: _ctrl.leaderboard,
                          drinks: _ctrl.drinks,
                          currentProfile: me,
                          onDeleteDrink: _ctrl.deleteDrink,
                          bodyProfile: _body.profile,
                          onOpenBodyMetrics: () =>
                              showBodyMetricsSheet(context),
                        )
                      else
                        Feed(
                          drinks: _ctrl.drinks,
                          reactions: _ctrl.reactions,
                          members: members,
                          currentProfile: me,
                          onToggleReaction: _ctrl.toggleReaction,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Undo Toast
          if (_undo != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 96,
              child: UndoToast(
                key: ValueKey(_undo!.drinkIds.first),
                info: _undo!,
                onUndo: _undoLast,
                onDismiss: () {
                  if (mounted) setState(() => _undo = null);
                },
              ),
            ),

          // Daumenzone
          if (!isEnded)
            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 12,
                children: [
                  if (last != null)
                    Flexible(
                      child: Pressable(
                        onTap: () => _quickRepeat(last),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.o(0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: white(0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: black(0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: [
                              Text(
                                last.icon,
                                style: const TextStyle(fontSize: 18, height: 1),
                              ),
                              Flexible(
                                child: Text(
                                  'Nochmal ${last.name}',
                                  maxLines: 1,
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
                    ),
                  Pressable(
                    onTap: _openDrinkSheet,
                    scale: 0.9,
                    child: Semantics(
                      label: 'Getränk hinzufügen',
                      button: true,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: glow(AppColors.lime),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 36,
                          color: Colors.black,
                          weight: 900,
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

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.tab,
    required this.feedCount,
    required this.onChanged,
  });

  final _Tab tab;
  final int feedCount;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item({
      required bool active,
      required Color color,
      required Color textColor,
      required VoidCallback onTap,
      required List<Widget> children,
    }) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? glow(color) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: children,
          ),
        ),
      ),
    );

    final rankActive = tab == _Tab.ranking;
    final feedActive = tab == _Tab.feed;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: white(0.05)),
      ),
      child: Row(
        children: [
          item(
            active: rankActive,
            color: AppColors.lime,
            textColor: Colors.black,
            onTap: () => onChanged(_Tab.ranking),
            children: [
              Text(
                '🏆 Live-Ranking',
                style: AppText.body(
                  12,
                  color: rankActive ? Colors.black : AppColors.dim,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          item(
            active: feedActive,
            color: AppColors.pink,
            textColor: Colors.white,
            onTap: () => onChanged(_Tab.feed),
            children: [
              Text(
                '⚡ Live-Feed',
                style: AppText.body(
                  12,
                  color: feedActive ? Colors.white : AppColors.dim,
                  weight: FontWeight.w700,
                ),
              ),
              if (feedCount > 0)
                Pill(
                  radius: 99,
                  background: white(0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  child: Text('$feedCount', style: AppText.mono(10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Party nicht gefunden', style: AppText.display(30)),
              const SizedBox(height: 8),
              Text(
                'Diese Party existiert nicht oder wurde gelöscht.',
                textAlign: TextAlign.center,
                style: AppText.body(12, color: AppColors.dim),
              ),
              const SizedBox(height: 24),
              NeonButton(
                onPressed: onBack,
                child: const Text('Zurück zur Übersicht'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedParty extends StatelessWidget {
  const _LockedParty({
    required this.name,
    required this.onUnlock,
    required this.onBack,
  });

  final String name;
  final VoidCallback onUnlock;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Pulse(
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.lime.o(0.3)),
                        boxShadow: glow(AppColors.lime, opacity: 0.2),
                      ),
                      child: const Text('🔒', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AppText.display(30),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'Diese Party ist mit einem 4-teiligen Symbol-Code geschützt. '
                      'Gib die 4 Symbole ein, um beizutreten!',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        12,
                        color: AppColors.dim,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  NeonButton(
                    onPressed: onUnlock,
                    child: const Text('Symbol-Code eingeben'),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onBack,
                    child: Text(
                      'Zurück zur Übersicht',
                      style: AppText.body(12, color: AppColors.faint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
