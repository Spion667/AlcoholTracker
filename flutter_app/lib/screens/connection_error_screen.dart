import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Gespeichertes Profil vorhanden, aber das Backend ist nicht erreichbar.
class ConnectionErrorScreen extends StatelessWidget {
  const ConnectionErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                const Text('📡', style: TextStyle(fontSize: 56)),
                Text('Keine Verbindung', style: AppText.display(34)),
                Text(
                  'Dein Profil konnte nicht geladen werden. Prüfe deine '
                  'Internetverbindung und versuche es erneut.',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: AppColors.dim, height: 1.5),
                ),
                const SizedBox(height: 8),
                NeonButton(
                  onPressed: profile.loading ? null : profile.init,
                  child: Text(profile.loading ? 'Lade …' : 'Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
