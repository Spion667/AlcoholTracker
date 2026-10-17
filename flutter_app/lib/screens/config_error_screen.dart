import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Wird angezeigt, wenn die App ohne Supabase-Konfiguration gebaut wurde.
class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  const Text('⚙️', style: TextStyle(fontSize: 40)),
                  Text(
                    'Supabase nicht konfiguriert',
                    style: AppText.display(30),
                  ),
                  Text(
                    'Starte die App mit den Schlüsseln deines Supabase-Projekts:',
                    style: AppText.body(13, color: AppColors.dim, height: 1.5),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: black(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      'flutter run \\\n'
                      '  --dart-define=SUPABASE_URL=https://<projekt>.supabase.co \\\n'
                      '  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...',
                      style: AppText.mono(11, color: AppColors.lime),
                    ),
                  ),
                  Text(
                    'Ohne Backend kannst du mit --dart-define=DEMO_MODE=true '
                    'eine Demo mit Beispieldaten starten.',
                    style: AppText.body(
                      12,
                      color: AppColors.faint,
                      height: 1.5,
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
