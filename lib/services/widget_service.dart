import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../models/entry.dart';
import '../services/stats_service.dart';
import '../utils/dates.dart';
import '../widgets/entry_card.dart';

/// Виджет на домашнем экране.
///
/// Виджет сам в базу не ходит и ходить не должен: она зашифрована, а ключ
/// лежит в системном хранилище приложения. Поэтому приложение кладёт для него
/// готовые строки, а виджет их только показывает.
class WidgetService {
  const WidgetService._();

  static const _androidName = 'WicklyWidget';

  /// Обновляет данные виджета. Зовётся после каждой правки записей.
  static Future<void> refresh(List<Entry> entries) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final now = DateTime.now();
      final streak = StatsService.streak(entries, now: now);
      await HomeWidget.saveWidgetData<String>(
        'streak',
        streak.current > 0 ? Dates.daysStreak(streak.current) : '',
      );

      // «В этот день»: короткая строка с годом и заголовком.
      final memory = entries
          .where((e) =>
              e.entryDate.month == now.month &&
              e.entryDate.day == now.day &&
              e.entryDate.year != now.year)
          .toList()
        ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

      await HomeWidget.saveWidgetData<String>(
        'memory',
        memory.isEmpty
            ? ''
            : '${Dates.yearsAgo(now.year - memory.first.entryDate.year)} · '
                '${_title(memory.first)}',
      );

      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (_) {
      // Виджета может не быть на экране вовсе — это не повод шуметь.
    }
  }

  static String _title(Entry e) {
    final title = e.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return EntryCard.previewOf(e);
  }
}
