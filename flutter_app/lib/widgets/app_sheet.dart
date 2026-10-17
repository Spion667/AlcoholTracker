import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Oeffnet ein Bottom-Sheet im App-Look (`.bottom-sheet`).
///
/// [builder] liefert den Inhalt; ein [AppSheetScaffold] sorgt fuer Header und
/// scrollenden Body.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxHeightFactor = 0.85,
  Color borderColor = const Color(0x1FFFFFFF),
  List<BoxShadow>? shadows,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: black(0.75),
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: 448),
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                (media.size.height - media.viewInsets.bottom) * maxHeightFactor,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              media.viewInsets.bottom > 0
                  ? 16
                  : (media.padding.bottom < 24 ? 24 : media.padding.bottom),
            ),
            decoration: BoxDecoration(
              color: AppColors.sheet,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(top: BorderSide(color: borderColor)),
              boxShadow:
                  shadows ??
                  [
                    BoxShadow(
                      color: black(0.5),
                      blurRadius: 40,
                      offset: const Offset(0, -8),
                    ),
                  ],
            ),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

/// Standard-Aufbau eines Sheets: Header mit Titel + Schliessen, Trennlinie, scrollender Inhalt.
class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    super.key,
    required this.title,
    required this.body,
    this.titleBuilder,
    this.pinned,
    this.subtitle,
    this.leading,
    this.onClose,
    this.footer,
    this.titleSize = 28,
    this.closeSize = 32,
    this.bodyPadding = const EdgeInsets.symmetric(vertical: 16),
  });

  final String title;

  /// Ersetzt den Standard-Titel (z. B. mit Icon davor).
  final Widget? titleBuilder;
  final String? subtitle;
  final Widget? leading;
  final Widget body;
  final Widget? footer;

  /// Bleibt unter dem Header stehen (scrollt nicht mit).
  final Widget? pinned;
  final VoidCallback? onClose;
  final double titleSize;
  final double closeSize;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBuilder ??
                        Text(title, style: AppText.display(titleSize)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: AppText.body(12, color: AppColors.dim),
                        ),
                      ),
                  ],
                ),
              ),
              CloseCircleButton(
                size: closeSize,
                onTap: onClose ?? () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        const Hairline(),
        ?pinned,
        Flexible(
          child: SingleChildScrollView(padding: bodyPadding, child: body),
        ),
        ?footer,
      ],
    );
  }
}
