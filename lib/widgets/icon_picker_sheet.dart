import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/icon_keys.dart';
import 'sheet_scaffold.dart';

/// Полный список иконок, разложенный по смыслу.
///
/// В редакторах эмоции, действия, трекера и дневника сетка показывает только
/// ходовую два десятка — иначе поле «Иконка» вытесняет с листа имя и цвет.
/// Остальные полторы сотни живут здесь.
///
/// Названия групп берём **литералами** `tr('ig_…')`: сторож словаря
/// (`test/strings_coverage_test.dart`) читает исходники регуляркой и
/// вычисленный ключ не увидит.
Future<String?> showIconPicker(
  BuildContext context, {
  required String selected,
  required Color tint,
}) =>
    showWicklySheet<String>(
      context,
      expand: true,
      builder: (_) => IconPickerBody(selected: selected, tint: tint),
    );

class IconPickerBody extends StatelessWidget {
  final String selected;
  final Color tint;

  const IconPickerBody({super.key, required this.selected, required this.tint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = <(String, List<String>)>[
      (tr('ig_people'), AppIcons.people),
      (tr('ig_feelings'), AppIcons.feelings),
      (tr('ig_body'), AppIcons.body),
      (tr('ig_food'), AppIcons.food),
      (tr('ig_household'), AppIcons.household),
      (tr('ig_work'), AppIcons.work),
      (tr('ig_leisure'), AppIcons.leisure),
      (tr('ig_outdoors'), AppIcons.outdoors),
      (tr('ig_journey'), AppIcons.journey),
      (tr('ig_symbols'), AppIcons.symbols),
    ];

    return SheetScaffold(
      title: tr('icon'),
      expand: true,
      action: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final (label, keys) = groups[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 22, bottom: 10),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Wrap(
                spacing: IconCell.gap,
                runSpacing: IconCell.gap,
                children: [
                  for (final key in keys)
                    IconCell(
                      icon: AppIcons.resolve(key),
                      selected: key == selected,
                      tint: tint,
                      onTap: () => Navigator.of(context).pop(key),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ячейка сетки иконок. Живёт здесь, а не в редакторе каталога: её рисуют
/// четыре листа сразу, и разъехавшийся размер сразу бросается в глаза.
class IconCell extends StatelessWidget {
  /// Сторона ячейки. Шесть штук с шагом [gap] ровно закрывают ширину листа
  /// на телефоне — иначе справа остаётся полоса в пол-ячейки.
  static const double cell = 50;
  static const double gap = 10;

  final IconData icon;
  final bool selected;
  final Color tint;
  final VoidCallback onTap;

  const IconCell({
    super.key,
    required this.icon,
    required this.selected,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? tint.withValues(alpha: 0.16) : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: cell,
          height: cell,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: tint, width: 2) : null,
          ),
          child: Icon(icon,
              size: 22, color: selected ? tint : scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Сетка «ходовое + кнопка ко всему списку» для редакторов.
///
/// Выбранная иконка встаёт первой, даже если её нет среди ходовых: иначе,
/// выбрав что-то из полного списка, человек видит сетку без отметки и решает,
/// что выбор не сохранился.
class IconChoiceGrid extends StatelessWidget {
  final String selected;
  final Color tint;
  final ValueChanged<String> onPick;

  /// Сколько ходовых иконок показать до кнопки «Ещё».
  final int count;

  const IconChoiceGrid({
    super.key,
    required this.selected,
    required this.tint,
    required this.onPick,
    this.count = 23,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = AppIcons.pickerOrder.take(count).toList();
    if (!shown.contains(selected)) shown.insert(0, selected);

    return Wrap(
      spacing: IconCell.gap,
      runSpacing: IconCell.gap,
      children: [
        for (final key in shown)
          IconCell(
            icon: AppIcons.resolve(key),
            selected: key == selected,
            tint: tint,
            onTap: () => onPick(key),
          ),
        Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              final picked =
                  await showIconPicker(context, selected: selected, tint: tint);
              if (picked != null) onPick(picked);
            },
            child: SizedBox(
              width: IconCell.cell,
              height: IconCell.cell,
              child: Icon(Icons.apps_rounded,
                  size: 21, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
