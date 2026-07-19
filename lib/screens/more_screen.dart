import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';

/// Один пункт хаба «Ещё».
class MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

/// «Ещё»: всё, что не влезло в четыре вкладки.
///
/// Дневники, настроение, трекеры, поиск, воспоминания и настройки — крупными
/// плитками, а не списком строк: сюда заходят редко и целясь, поэтому важнее
/// разборчивость, чем плотность.
class MoreScreen extends StatelessWidget {
  final List<MoreItem>? items;

  const MoreScreen({super.key, this.items});

  @override
  Widget build(BuildContext context) {
    final list = items ?? const <MoreItem>[];
    return Scaffold(
      appBar: AppBar(title: Text(tr('tab_more'))),
      body: GridView.count(
        crossAxisCount: WicklyDesign.gridColumns(context, 260),
        padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 8,
            WicklyDesign.screenPad, 24),
        crossAxisSpacing: WicklyDesign.gapCards,
        mainAxisSpacing: WicklyDesign.gapCards,
        childAspectRatio: 1.35,
        children: [
          for (var i = 0; i < list.length; i++)
            Reveal(
              delay: Duration(milliseconds: 40 * (i < 5 ? i : 5)),
              child: _MoreTile(item: list[i]),
            ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final MoreItem item;
  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.all(WicklyDesign.gapInside),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon,
                      size: 20, color: scheme.onPrimaryContainer),
                ),
                const Spacer(),
                // Длинный заголовок ужимаем: «Эмоции и де…» читается как сбой.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.title,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 12,
                    height: 1.3,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
