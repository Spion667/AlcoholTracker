import 'package:flutter/material.dart';

import '../models/drink.dart';
import '../models/party.dart';
import '../models/profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/drinks.dart';
import '../utils/format.dart';
import 'common.dart';

const reactionEmojis = ['🔥', '🍻', '😵', '🫡', '💧'];

class _FeedItem {
  _FeedItem({
    required this.isRound,
    required this.id,
    required this.drink,
    required this.drinkIds,
    required this.loggedBy,
    required this.createdAt,
    this.profileId,
    this.recipients = const [],
  });

  final bool isRound;
  final String id;
  final Drink drink;
  final List<String> drinkIds;
  final String? loggedBy;
  final DateTime createdAt;
  final String? profileId; // nur Einzel-Drink
  final List<String> recipients; // nur Runde
}

/// Gruppiert Drinks mit gleicher `round_id` zu Runden (nur bei > 1 Person).
List<_FeedItem> _buildFeed(List<Drink> drinks) {
  final rounds = <String, _FeedItem>{};
  final roundDrinkIds = <String, List<String>>{};
  final roundRecipients = <String, List<String>>{};
  final singles = <_FeedItem>[];

  for (final d in drinks) {
    final rid = d.roundId;
    if (rid != null) {
      if (!rounds.containsKey(rid)) {
        rounds[rid] = _FeedItem(
          isRound: true,
          id: rid,
          drink: d,
          drinkIds: roundDrinkIds[rid] = [d.id],
          recipients: roundRecipients[rid] = [d.profileId],
          loggedBy: d.loggedBy,
          createdAt: d.createdAt,
        );
      } else {
        roundDrinkIds[rid]!.add(d.id);
        if (!roundRecipients[rid]!.contains(d.profileId)) {
          roundRecipients[rid]!.add(d.profileId);
        }
      }
    } else {
      singles.add(
        _FeedItem(
          isRound: false,
          id: d.id,
          drink: d,
          drinkIds: [d.id],
          profileId: d.profileId,
          loggedBy: d.loggedBy,
          createdAt: d.createdAt,
        ),
      );
    }
  }

  final actualRounds = <_FeedItem>[];
  for (final r in rounds.values) {
    if (r.recipients.length > 1) {
      actualRounds.add(r);
    } else {
      singles.add(
        _FeedItem(
          isRound: false,
          id: r.drinkIds.first,
          drink: r.drink,
          drinkIds: r.drinkIds,
          profileId: r.recipients.first,
          loggedBy: r.loggedBy,
          createdAt: r.createdAt,
        ),
      );
    }
  }

  return [...actualRounds, ...singles]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// Chronologischer Live-Feed mit Emoji-Reaktionen.
class Feed extends StatelessWidget {
  const Feed({
    super.key,
    required this.drinks,
    required this.reactions,
    required this.members,
    required this.currentProfile,
    required this.onToggleReaction,
  });

  final List<Drink> drinks;
  final List<Reaction> reactions;
  final List<PartyMember> members;
  final Profile currentProfile;
  final Future<void> Function(String drinkId, String emoji) onToggleReaction;

  @override
  Widget build(BuildContext context) {
    final memberMap = {for (final m in members) m.id: m.profile};
    final items = _buildFeed(drinks);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            const Text('🧊', style: TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(
              'Noch keine Aktivität. Wer trinkt den ersten Schluck?',
              textAlign: TextAlign.center,
              style: AppText.body(14, color: AppColors.dim),
            ),
          ],
        ),
      );
    }

    return Column(
      spacing: 12,
      children: [
        for (final item in items)
          _FeedCard(
            key: ValueKey(item.id),
            item: item,
            memberMap: memberMap,
            me: currentProfile,
            reactions: reactions
                .where((r) => item.drinkIds.contains(r.drinkId))
                .toList(),
            onToggleReaction: onToggleReaction,
          ),
      ],
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    super.key,
    required this.item,
    required this.memberMap,
    required this.me,
    required this.reactions,
    required this.onToggleReaction,
  });

  final _FeedItem item;
  final Map<String, Profile> memberMap;
  final Profile me;
  final List<Reaction> reactions;
  final Future<void> Function(String, String) onToggleReaction;

  static const _unknown = Profile(id: '?', name: 'Jemand', emoji: '👤');

  @override
  Widget build(BuildContext context) {
    final ago = timeAgo(item.createdAt);
    final bold = AppText.body(12, weight: FontWeight.w700);
    final lime = AppText.body(
      12,
      color: AppColors.lime,
      weight: FontWeight.w700,
    );
    final base = AppText.body(12, height: 1.35);

    Widget content;
    if (item.isRound) {
      final host = memberMap[item.loggedBy] ?? _unknown;
      final isMeHost = item.loggedBy == me.id;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiTile(
                emoji: item.drink.icon,
                size: 36,
                radius: 12,
                fontSize: 18,
                background: AppColors.pink.o(0.15),
                borderColor: AppColors.pink.o(0.3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: base,
                        children: [
                          TextSpan(
                            text: isMeHost ? 'Du' : host.name,
                            style: AppText.body(
                              12,
                              color: AppColors.pink,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: ' hat eine Runde '),
                          TextSpan(text: item.drink.name, style: bold),
                          const TextSpan(text: ' für '),
                          TextSpan(
                            text: '${item.recipients.length} Personen',
                            style: lime,
                          ),
                          const TextSpan(text: ' ausgegeben! 🎉'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(ago, style: AppText.mono(10, color: AppColors.faint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: white(0.04))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 4,
                children: [
                  Text(
                    'Runde für:',
                    style: AppText.body(10, color: AppColors.faint),
                  ),
                  for (final recId in item.recipients)
                    if (memberMap[recId] case final rec?)
                      Pill(
                        radius: 8,
                        background: white(0.05),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            Text(
                              rec.emoji,
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              rec.id == me.id ? 'Du' : rec.name,
                              style: AppText.body(10, color: AppColors.dim),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      final drinker = memberMap[item.profileId] ?? _unknown;
      final isMe = item.profileId == me.id;
      final loggedByOther =
          item.loggedBy != null && item.loggedBy != item.profileId;
      final logger = memberMap[item.loggedBy] ?? _unknown;

      final List<InlineSpan> action;
      if (isMe) {
        action = loggedByOther
            ? [
                TextSpan(text: logger.name, style: bold),
                const TextSpan(text: ' hat dir ein '),
                TextSpan(text: item.drink.name, style: lime),
                const TextSpan(text: ' eingetragen'),
              ]
            : [
                TextSpan(text: 'Du', style: bold),
                const TextSpan(text: ' trinkst '),
                TextSpan(text: item.drink.name, style: lime),
              ];
      } else if (item.loggedBy == me.id) {
        action = [
          TextSpan(text: 'Du', style: bold),
          const TextSpan(text: ' hast für '),
          TextSpan(text: drinker.name, style: bold),
          const TextSpan(text: ' ein '),
          TextSpan(text: item.drink.name, style: lime),
          const TextSpan(text: ' eingetragen'),
        ];
      } else {
        action = [
          TextSpan(text: drinker.name, style: bold),
          const TextSpan(text: ' trinkt '),
          TextSpan(text: item.drink.name, style: lime),
        ];
      }

      String num0(double v) =>
          v == v.roundToDouble() ? v.toInt().toString() : v.toString();
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiTile(
            emoji: item.drink.icon,
            size: 36,
            radius: 12,
            fontSize: 18,
            background: AppColors.surfaceLight,
            borderColor: white(0.05),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text.rich(TextSpan(style: base, children: action)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${formatGrams(item.drink.alcoholG)}g',
                      style: AppText.mono(
                        10,
                        color: AppColors.lime,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${num0(item.drink.volumeMl)}ml (${num0(item.drink.abv)}%) · $ago',
                  style: AppText.mono(10, color: AppColors.faint),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: white(0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: white(0.04))),
            ),
            child: Row(
              spacing: 6,
              children: [
                for (final emoji in reactionEmojis)
                  _ReactionChip(
                    emoji: emoji,
                    count: reactions.where((r) => r.emoji == emoji).length,
                    active: reactions.any(
                      (r) => r.emoji == emoji && r.profileId == me.id,
                    ),
                    // Erste drink_id fuer das Umschalten (wie in der Web-App).
                    onTap: () => onToggleReaction(item.drinkIds.first, emoji),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.lime.o(0.2) : white(0.03),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? AppColors.lime.o(0.4) : white(0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 0)
              Text(
                '$count',
                style: AppText.mono(
                  10,
                  color: active ? Colors.white : AppColors.dim,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
