import 'package:flutter/material.dart';

import '../models/body_profile.dart';
import '../models/drink.dart';
import '../models/profile.dart';
import '../state/party_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/bac.dart';
import '../utils/drinks.dart';
import '../utils/format.dart';
import 'common.dart';

/// Live-Ranking nach Gramm reinem Alkohol inkl. Meilenstein, Badges und Promille.
class Leaderboard extends StatefulWidget {
  const Leaderboard({
    super.key,
    required this.leaderboard,
    required this.drinks,
    required this.currentProfile,
    required this.onDeleteDrink,
    this.bodyProfile,
    this.onOpenBodyMetrics,
  });

  final List<LeaderboardEntry> leaderboard;
  final List<Drink> drinks;
  final Profile currentProfile;
  final Future<void> Function(String drinkId) onDeleteDrink;
  final BodyProfile? bodyProfile;
  final VoidCallback? onOpenBodyMetrics;

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final leaderboard = widget.leaderboard;
    if (leaderboard.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'Noch keine Teilnehmer in dieser Party.',
            style: AppText.body(14, color: AppColors.dim),
          ),
        ),
      );
    }

    final me = widget.currentProfile;
    final leaderMax = leaderboard.first.totalAlcoholGrams < 1
        ? 1.0
        : leaderboard.first.totalAlcoholGrams;

    final myDrinks = widget.drinks.where((d) => d.profileId == me.id).toList();
    final myBac = calculateBacFromDrinks(myDrinks, widget.bodyProfile);
    final badgeMap = computeBadges(
      widget.drinks,
      leaderboard.map((l) => l.profile).toList(),
    );
    final totalGroup = widget.drinks.fold<double>(0, (s, d) => s + d.alcoholG);
    final milestone = getGroupMilestoneInfo(totalGroup);

    return Column(
      spacing: 12,
      children: [
        _MilestoneCard(info: milestone),
        for (final item in leaderboard)
          _Row(
            key: ValueKey(item.profile.id),
            item: item,
            isMe: item.profile.id == me.id,
            isLeader: item.rank == 1 && item.totalAlcoholGrams > 0,
            percentOfLeader: (item.totalAlcoholGrams / leaderMax).clamp(
              0.0,
              1.0,
            ),
            expanded: _expandedId == item.profile.id,
            userDrinks: widget.drinks
                .where((d) => d.profileId == item.profile.id)
                .toList(),
            badges: badgeMap[item.profile.id] ?? const [],
            currentProfile: me,
            myBac: myBac,
            bodyProfile: widget.bodyProfile,
            onToggle: () => setState(() {
              _expandedId = _expandedId == item.profile.id
                  ? null
                  : item.profile.id;
            }),
            onDeleteDrink: widget.onDeleteDrink,
            onOpenBodyMetrics: widget.onOpenBodyMetrics,
          ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.info});

  final MilestoneInfo info;

  @override
  Widget build(BuildContext context) {
    final next = info.nextMilestone;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: white(0.10)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18182C), AppColors.surface, Color(0xFF10101C)],
        ),
        boxShadow: [
          BoxShadow(
            color: black(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        spacing: 10,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.lime.o(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lime.o(0.2)),
                ),
                child: Text(next.icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          next.title,
                          style: AppText.body(12, weight: FontWeight.w700),
                        ),
                        Pill(
                          background: white(0.10),
                          child: Text(
                            'Ziel: ${next.target}g',
                            style: AppText.mono(10, color: AppColors.dim),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Noch ${info.gramsRemaining}g Reinalkohol bis zum Meilenstein 🔥',
                      style: AppText.body(11, color: AppColors.dim),
                    ),
                  ],
                ),
              ),
              Text(
                '${info.percent}%',
                style: AppText.mono(
                  12,
                  color: AppColors.lime,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            height: 8,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: white(0.05),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: white(0.05)),
            ),
            child: LayoutBuilder(
              builder: (context, c) => Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: c.maxWidth * info.percent / 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.lime,
                        Color(0xFFE2FF66),
                        AppColors.pink,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Promillewerte bewusst in Inter statt Space Mono: Dessen ‰-Glyph ist bei
/// kleiner Schrift kaum von % zu unterscheiden (Faktor 10!).
final _bacStyle = AppText.body(
  11,
  color: AppColors.cyan,
  weight: FontWeight.w700,
).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.item,
    required this.isMe,
    required this.isLeader,
    required this.percentOfLeader,
    required this.expanded,
    required this.userDrinks,
    required this.badges,
    required this.currentProfile,
    required this.myBac,
    required this.bodyProfile,
    required this.onToggle,
    required this.onDeleteDrink,
    required this.onOpenBodyMetrics,
  });

  final LeaderboardEntry item;
  final bool isMe;
  final bool isLeader;
  final double percentOfLeader;
  final bool expanded;
  final List<Drink> userDrinks;
  final List<DrinkBadge> badges;
  final Profile currentProfile;
  final BacResult myBac;
  final BodyProfile? bodyProfile;
  final VoidCallback onToggle;
  final Future<void> Function(String) onDeleteDrink;
  final VoidCallback? onOpenBodyMetrics;

  @override
  Widget build(BuildContext context) {
    final profile = item.profile;
    final rankColor = switch (item.rank) {
      2 => const Color(0xFFD1D5DB),
      3 => const Color(0xFFD97706),
      _ => AppColors.faint,
    };

    final detailStyle = AppText.mono(11, color: AppColors.dim);
    final detail = <Widget>[
      Text(
        '${item.totalDrinksCount} ${item.totalDrinksCount == 1 ? 'Drink' : 'Drinks'}',
        style: detailStyle,
      ),
      if (item.totalBeerLiters > 0) ...[
        Text('·', style: detailStyle),
        Text(
          '${item.totalBeerLiters.toStringAsFixed(1)}L Bier',
          style: detailStyle,
        ),
      ],
      // Promillewert des aktuellen Nutzers
      if (isMe && !myBac.isZero) ...[
        Text('·', style: detailStyle),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(myBac.formattedBac, style: _bacStyle),
            if (bodyProfile?.shareInParty != true)
              Opacity(
                opacity: 0.8,
                child: const Icon(
                  Icons.lock_rounded,
                  size: 10,
                  color: AppColors.cyan,
                ),
              ),
          ],
        ),
      ],
      // Nudge: noch keine Koerperdaten hinterlegt
      if (isMe && bodyProfile == null) ...[
        Text('·', style: detailStyle),
        Pressable(
          onTap: onOpenBodyMetrics,
          child: Pill(
            radius: 6,
            background: AppColors.cyan.o(0.15),
            borderColor: AppColors.cyan.o(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                const Icon(Icons.lock_rounded, size: 10, color: AppColors.cyan),
                Text(
                  '+ Promille',
                  style: AppText.body(
                    10,
                    color: AppColors.cyan,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      // Promillewert fuer andere Mitglieder (falls geteilt)
      if (!isMe && item.member.currentBac != null) ...[
        Text('·', style: detailStyle),
        Text(
          '~${commaDecimal(item.member.currentBac!, 2)} ‰',
          style: _bacStyle,
        ),
      ],
    ];

    final borderColor = isMe
        ? AppColors.lime.o(0.4)
        : isLeader
        ? AppColors.pink.o(0.4)
        : white(0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isMe ? AppColors.surface.o(0.95) : AppColors.surface.o(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isMe
            ? glow(AppColors.lime)
            : isLeader
            ? glow(AppColors.pink)
            : null,
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: isLeader
                          ? const Pulse(
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                size: 22,
                                color: AppColors.pink,
                              ),
                            )
                          : Text(
                              '#${item.rank}',
                              style: AppText.display(20, color: rankColor),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  EmojiTile(
                    emoji: profile.emoji,
                    size: 44,
                    radius: 16,
                    fontSize: 24,
                    background: profile.colorValue.o(0.13),
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
                                profile.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isMe)
                              Pill(
                                background: AppColors.lime,
                                child: Text(
                                  'DU',
                                  style: AppText.body(
                                    10,
                                    color: Colors.black,
                                    weight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (profile.isGuest)
                              Pill(
                                radius: 4,
                                background: white(0.05),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  'Gast',
                                  style: AppText.body(
                                    10,
                                    color: AppColors.faint,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: detail,
                        ),
                        const SizedBox(height: 6),
                        // Fortschrittsbalken relativ zum Leader
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: white(0.06),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: percentOfLeader),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (context, v, _) => FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: v,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99),
                                  color: isLeader
                                      ? null
                                      : AppColors.lime.o(0.8),
                                  gradient: isLeader
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.pink,
                                            AppColors.purple,
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (badges.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final b in badges)
                                Pill(
                                  radius: 6,
                                  background: b.color.o(0.09),
                                  borderColor: b.color.o(0.21),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 4,
                                    children: [
                                      Text(
                                        b.icon,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          height: 1,
                                        ),
                                      ),
                                      Text(
                                        b.label,
                                        style: AppText.body(
                                          10,
                                          color: b.color,
                                          weight: FontWeight.w700,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: formatGrams(item.totalAlcoholGrams)),
                            TextSpan(
                              text: 'g',
                              style: AppText.body(
                                12,
                                color: AppColors.lime,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        style: AppText.display(24),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ALKOHOL',
                        style: AppText.body(
                          10,
                          color: AppColors.faint,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.faint,
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
                ? _Details(
                    isMe: isMe,
                    myBac: myBac,
                    bodyProfile: bodyProfile,
                    userDrinks: userDrinks,
                    currentProfile: currentProfile,
                    onDeleteDrink: onDeleteDrink,
                    onOpenBodyMetrics: onOpenBodyMetrics,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.isMe,
    required this.myBac,
    required this.bodyProfile,
    required this.userDrinks,
    required this.currentProfile,
    required this.onDeleteDrink,
    required this.onOpenBodyMetrics,
  });

  final bool isMe;
  final BacResult myBac;
  final BodyProfile? bodyProfile;
  final List<Drink> userDrinks;
  final Profile currentProfile;
  final Future<void> Function(String) onDeleteDrink;
  final VoidCallback? onOpenBodyMetrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: black(0.4),
        border: Border(top: BorderSide(color: white(0.06))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          // Promille- & Ausnuechterungs-Prognose fuer den eigenen User
          if (isMe && bodyProfile != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cyan.o(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan.o(0.2)),
              ),
              child: Row(
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myBac.isZero
                              ? 'Promille-Pegel: 0,0 ‰ (Nüchtern)'
                              : 'Promille-Pegel: ${myBac.formattedBac}',
                          style: AppText.body(12, weight: FontWeight.w700),
                        ),
                        Text(
                          myBac.isZero
                              ? 'Aktuell kein Restalkohol im Blut.'
                              : 'Voraussichtlich wieder bei 0,0 ‰ gegen ${myBac.soberTimeString}',
                          style: AppText.body(11, color: AppColors.dim),
                        ),
                      ],
                    ),
                  ),
                  if (onOpenBodyMetrics != null)
                    GestureDetector(
                      onTap: onOpenBodyMetrics,
                      child: Text(
                        'Körperdaten',
                        style: AppText.body(
                          10,
                          color: AppColors.cyan,
                          weight: FontWeight.w700,
                        ).copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                ],
              ),
            ),
          Text(
            'GETRÄNKE (${userDrinks.length})',
            style: AppText.label(size: 10),
          ),
          if (userDrinks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'Noch keine Getränke geloggt.',
                  style: AppText.body(12, color: AppColors.dim),
                ),
              ),
            )
          else
            for (final drink in userDrinks)
              _DrinkLine(
                drink: drink,
                // Eigene Getraenke ODER Getraenke, die man selbst eingetragen hat.
                canDelete:
                    drink.profileId == currentProfile.id ||
                    drink.loggedBy == currentProfile.id,
                onDelete: () => onDeleteDrink(drink.id),
              ),
        ],
      ),
    );
  }
}

class _DrinkLine extends StatelessWidget {
  const _DrinkLine({
    required this.drink,
    required this.canDelete,
    required this.onDelete,
  });

  final Drink drink;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    String num0(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: white(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: white(0.04)),
      ),
      child: Row(
        children: [
          Text(drink.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    drink.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(12, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${num0(drink.volumeMl)}ml · ${num0(drink.abv)}%)',
                  style: AppText.mono(10, color: AppColors.dim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${formatGrams(drink.alcoholG)}g',
            style: AppText.mono(
              11,
              color: AppColors.lime,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatClock(drink.createdAt),
            style: AppText.mono(11, color: AppColors.faint),
          ),
          if (canDelete)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.faint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
