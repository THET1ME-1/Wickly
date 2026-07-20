import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';

/// Boosty — подписка и разовая поддержка.
final Uri kBoostyUrl = Uri.parse('https://boosty.to/sntcompany');

/// DonationAlerts — разовый донат картой или через СБП.
final Uri kDonationAlertsUrl =
    Uri.parse('https://www.donationalerts.com/r/thet1me');

Future<void> openBoosty() async {
  await launchUrl(kBoostyUrl, mode: LaunchMode.externalApplication);
}

Future<void> openDonationAlerts() async {
  await launchUrl(kDonationAlertsUrl, mode: LaunchMode.externalApplication);
}

/// Блок «Поддержать авторов»: короткий текст и две кнопки-ссылки.
///
/// Стоит внизу «Ещё» — не мешает тем, кто пришёл за дневником, и находится
/// теми, кто ищет, куда занести деньги. Цвет мягче обычной карточки: блок
/// заметен, но не спорит с плитками разделов.
class SupportCard extends StatelessWidget {
  const SupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(WicklyDesign.gapInside),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.volunteer_activism_rounded,
                    size: 22, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('support_authors'),
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr('support_intro'),
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 13,
                height: 1.35,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: openBoosty,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.favorite_rounded, size: 19),
              label: const Text(
                'Boosty',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: openDonationAlerts,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.card_giftcard_rounded, size: 19),
              label: const Text(
                'DonationAlerts',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
