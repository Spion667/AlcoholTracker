import 'package:flutter/material.dart';

import '../config/version.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_sheet.dart';
import 'common.dart';

Future<void> showChangelogSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    borderColor: AppColors.cyan.o(0.2),
    builder: (ctx) => AppSheetScaffold(
      title: 'Versionshinweise',
      titleBuilder: Row(
        spacing: 10,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cyan.o(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyan.o(0.2)),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 16,
              color: AppColors.cyan,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Versionshinweise', style: AppText.display(24)),
              Text(
                'Aktuell: v$appVersion · $appReleaseDate',
                style: AppText.mono(10, color: AppColors.faint),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        spacing: 16,
        children: [
          for (final rel in releases)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: rel.badge != null ? AppColors.surfaceLight : white(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: rel.badge != null
                      ? AppColors.cyan.o(0.3)
                      : white(0.05),
                ),
                boxShadow: rel.badge != null
                    ? [BoxShadow(color: AppColors.cyan.o(0.08), blurRadius: 20)]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Text(
                            'v${rel.version}',
                            style: AppText.mono(
                              12,
                              color: AppColors.lime,
                              weight: FontWeight.w700,
                            ),
                          ),
                          if (rel.badge != null)
                            Pill(
                              radius: 99,
                              background: AppColors.cyan.o(0.15),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
                              ),
                              child: Text(
                                rel.badge!,
                                style: AppText.body(
                                  10,
                                  color: AppColors.cyan,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        rel.date,
                        style: AppText.mono(10, color: AppColors.faint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rel.title,
                    style: AppText.body(14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final h in rel.highlights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 14,
                              color: AppColors.lime,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h,
                              style: AppText.body(
                                12,
                                color: AppColors.dim,
                                height: 1.35,
                              ),
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
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: NeonButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Schließen'),
        ),
      ),
    ),
  );
}
