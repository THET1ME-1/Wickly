import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../l10n/strings.dart';
import '../services/notifications_service.dart';
import '../services/prompts.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';
import '../widgets/settings_scaffold.dart';

/// Напоминания и подсказки.
///
/// Дневник напоминает мягко и по расписанию, которое человек задал сам:
/// время, дни недели и утренние воспоминания. Подсказка дня стоит здесь же —
/// это ответ на «не знаю, с чего начать», а не отдельная функция.
class RemindersScreen extends StatefulWidget {
  /// Начать запись с подсказки.
  final void Function(String promptKey)? onAnswer;

  const RemindersScreen({super.key, this.onAnswer});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late String _promptKey;

  @override
  void initState() {
    super.initState();
    _promptKey = Prompts.keyOfDay(AppPrefs.instance.promptPack, DateTime.now());
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await NotificationsService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('notifications_denied'))),
          );
        }
        return;
      }
    }
    await AppPrefs.instance.setReminder(value);
    await NotificationsService.reschedule();
    if (mounted) setState(() {});
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: AppPrefs.instance.reminderTime,
    );
    if (picked == null) return;
    await AppPrefs.instance.setReminderTime(picked);
    await NotificationsService.reschedule();
    if (mounted) setState(() {});
  }

  Future<void> _toggleDay(int weekday) async {
    final days = [...AppPrefs.instance.reminderDays];
    if (days.contains(weekday)) {
      // Последний день не снимаем: напоминание без дней — выключенное
      // напоминание, для этого есть тумблер.
      if (days.length == 1) return;
      days.remove(weekday);
    } else {
      days.add(weekday);
    }
    await AppPrefs.instance.setReminderDays(days);
    await NotificationsService.reschedule();
    if (mounted) setState(() {});
  }

  Future<void> _setPack(String pack) async {
    await AppPrefs.instance.setPromptPack(pack);
    if (mounted) {
      setState(() => _promptKey = Prompts.keyOfDay(pack, DateTime.now()));
    }
  }

  Future<void> _toggleMemories(bool value) async {
    if (value) {
      final granted = await NotificationsService.requestPermission();
      if (!granted) return;
    }
    await AppPrefs.instance.setMemories(value);
    await NotificationsService.reschedule();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = AppPrefs.instance;

    return Scaffold(
      appBar: AppBar(title: Text(tr('reminders'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 4,
            WicklyDesign.screenPad, 28),
        children: [
          Reveal(
            child: SettingsGroup([
              SettingsRow(
                icon: Icons.notifications_rounded,
                title: tr('reminder_daily'),
                subtitle: tr('reminder_daily_sub'),
                trailing: Switch(
                  value: prefs.reminder,
                  onChanged: _toggleReminder,
                ),
                onTap: () => _toggleReminder(!prefs.reminder),
              ),
              if (prefs.reminder) ...[
                const SettingsDivider(),
                _TimeRow(
                  time: prefs.reminderTime,
                  days: prefs.reminderDays,
                  onPickTime: _pickTime,
                  onToggleDay: _toggleDay,
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          Reveal(
            delay: const Duration(milliseconds: 60),
            child: _PromptCard(
              promptKey: _promptKey,
              onAnswer: () => widget.onAnswer?.call(_promptKey),
              onAnother: () => setState(() =>
                  _promptKey = Prompts.next(prefs.promptPack, _promptKey)),
            ),
          ),
          const SizedBox(height: 16),

          Reveal(
            delay: const Duration(milliseconds: 120),
            child: Container(
              padding: const EdgeInsets.all(WicklyDesign.gapInside),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('prompt_packs'),
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final pack in Prompts.packs)
                        _PackChip(
                          label: Prompts.packLabel(pack),
                          selected: prefs.promptPack == pack,
                          onTap: () => _setPack(pack),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Reveal(
            delay: const Duration(milliseconds: 160),
            child: SettingsGroup([
              SettingsRow(
                icon: Icons.history_rounded,
                title: tr('memories_morning'),
                subtitle: tr('memories_morning_sub'),
                trailing: Switch(
                  value: prefs.memories,
                  onChanged: _toggleMemories,
                ),
                onTap: () => _toggleMemories(!prefs.memories),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Время напоминания и дни недели.
class _TimeRow extends StatelessWidget {
  final TimeOfDay time;
  final List<int> days;
  final VoidCallback onPickTime;
  final ValueChanged<int> onToggleDay;

  const _TimeRow({
    required this.time,
    required this.days,
    required this.onPickTime,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = tr('weekdays_short').split(',');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: [
          PressableScale(
            child: GestureDetector(
              onTap: onPickTime,
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:'
                '${time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                  letterSpacing: -1,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Дни недели точками: занимают вдвое меньше места, чем подписи,
          // и читаются с одного взгляда.
          for (var d = 1; d <= 7; d++)
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: GestureDetector(
                onTap: () => onToggleDay(d),
                child: Tooltip(
                  message: labels.length >= d ? labels[d - 1] : '$d',
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: days.contains(d)
                          ? scheme.primary
                          : Colors.transparent,
                      border: days.contains(d)
                          ? null
                          : Border.all(color: scheme.outlineVariant, width: 1.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Подсказка дня с двумя кнопками.
class _PromptCard extends StatelessWidget {
  final String promptKey;
  final VoidCallback onAnswer;
  final VoidCallback onAnother;

  const _PromptCard({
    required this.promptKey,
    required this.onAnswer,
    required this.onAnother,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(WicklyDesign.gapInside),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 14, color: scheme.onPrimaryContainer),
              const SizedBox(width: 6),
              Text(
                tr('prompt_of_day').toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr(promptKey),
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.3,
              letterSpacing: -0.3,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  backgroundColor: scheme.onPrimaryContainer,
                  foregroundColor: scheme.primaryContainer,
                ),
                onPressed: onAnswer,
                child: Text(tr('prompt_answer')),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: const StadiumBorder(),
                  foregroundColor: scheme.onPrimaryContainer,
                  side: BorderSide(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.4),
                  ),
                ),
                onPressed: onAnother,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(tr('prompt_another')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PackChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Ширина по содержимому: в Wrap пилюля с Center растянулась бы на строку.
    return Material(
      color:
          selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
