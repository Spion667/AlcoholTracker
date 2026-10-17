import 'dart:ui';

import '../theme/app_colors.dart';

class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.emoji = '😎',
    this.color = '#C6FF3D',
    this.isGuest = false,
  });

  final String id;
  final String name;
  final String emoji;
  final String color;
  final bool isGuest;

  Color get colorValue => hexToColor(color, fallback: AppColors.lime);

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    emoji: (json['emoji'] as String?) ?? '😎',
    color: (json['color'] as String?) ?? '#C6FF3D',
    isGuest: (json['is_guest'] as bool?) ?? false,
  );
}
