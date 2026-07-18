import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../l10n/strings.dart';
import '../models/catalog.dart';
import '../theme/app_theme.dart';
import '../theme/icon_keys.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/catalog_names.dart';
import '../utils/dates.dart';
import 'catalog_editor_sheet.dart';
import 'pressable.dart';
import 'sheet_scaffold.dart';

/// Что человек отметил на листе настроения.
class MoodResult {
  final int? mood;
  final List<String> emotionIds;
  final List<String> activityIds;

  const MoodResult({
    this.mood,
    this.emotionIds = const [],
    this.activityIds = const [],
  });
}

/// Лист настроения: шкала, эмоции за ней и действия дня.
///
/// Шкала крупная и подписанная — по цветному кружку без подписи человек через
/// месяц не вспомнит, что значит третий слева. Эмоции и действия — свои: набор
/// правится тут же кнопкой «＋ своё».
Future<MoodResult?> showMoodSheet(
  BuildContext context, {
  required String entryId,
  int? mood,
  required DateTime at,
}) =>
    showWicklySheet<MoodResult>(
      context,
      builder: (_) => _MoodSheet(entryId: entryId, mood: mood, at: at),
    );

/// Тот же лист, но как экран — для снимков в `test_golden`: модальный лист в
/// снимок целиком не попадает.
@visibleForTesting
class MoodSheetPreview extends StatelessWidget {
  final DateTime at;
  final int? mood;

  const MoodSheetPreview({super.key, required this.at, this.mood});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: _MoodSheet(entryId: 'preview', mood: mood, at: at),
      );
}

class _MoodSheet extends StatefulWidget {
  final String entryId;
  final int? mood;
  final DateTime at;

  const _MoodSheet({required this.entryId, this.mood, required this.at});

  @override
  State<_MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends State<_MoodSheet> {
  int? _mood;
  List<Emotion> _emotions = const [];
  List<Activity> _activities = const [];
  final _pickedEmotions = <String>{};
  final _pickedActivities = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _mood = widget.mood;
    _load();
  }

  Future<void> _load() async {
    final catalog = CatalogRepository.instance;
    final emotions = await catalog.emotions();
    final activities = await catalog.activities();
    final pickedE = await catalog.emotionIdsOf(widget.entryId);
    final pickedA = await catalog.activityIdsOf(widget.entryId);
    if (!mounted) return;
    setState(() {
      _emotions = emotions;
      _activities = activities;
      _pickedEmotions
        ..clear()
        ..addAll(pickedE);
      _pickedActivities
        ..clear()
        ..addAll(pickedA);
      _loading = false;
    });
  }

  Future<void> _save() async {
    await CatalogRepository.instance
        .setEmotionsOf(widget.entryId, _pickedEmotions.toList());
    await CatalogRepository.instance
        .setActivitiesOf(widget.entryId, _pickedActivities.toList());
    if (!mounted) return;
    Navigator.of(context).pop(MoodResult(
      mood: _mood,
      emotionIds: _pickedEmotions.toList(),
      activityIds: _pickedActivities.toList(),
    ));
  }

  Future<void> _newEmotion(EmotionKind kind) async {
    final created = await showEmotionEditor(context, kind: kind);
    if (created == null) return;
    await _load();
    setState(() => _pickedEmotions.add(created.id));
  }

  Future<void> _newActivity(ActivityCategory category) async {
    final created = await showActivityEditor(context, category: category);
    if (created == null) return;
    await _load();
    setState(() => _pickedActivities.add(created.id));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SheetScaffold(
      bottom: FilledButton(
        onPressed: _save,
        child: Text(tr('save')),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: WicklyDesign.screenPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    _mood == null
                        ? tr('set_mood')
                        : MoodPaletteX.label(_mood!),
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.3,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Dates.dayLong(widget.at),
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Scale(
              value: _mood,
              onPick: (m) => setState(() => _mood = m == _mood ? null : m),
            ),
            const SizedBox(height: 22),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _Section(title: tr('mood_behind')),
              _ChipsWrap(
                children: [
                  for (final e in _emotions)
                    _CatalogChip(
                      label: CatalogNames.of(e),
                      color: e.color == null
                          ? _emotionTone(context, e.kind)
                          : Color(e.color!),
                      selected: _pickedEmotions.contains(e.id),
                      onTap: () => setState(() => _pickedEmotions.contains(e.id)
                          ? _pickedEmotions.remove(e.id)
                          : _pickedEmotions.add(e.id)),
                    ),
                  _AddChip(onTap: () => _newEmotion(EmotionKind.pleasant)),
                ],
              ),
              const SizedBox(height: 18),
              _Section(title: tr('mood_did')),
              _ChipsWrap(
                children: [
                  for (final a in _activities)
                    _CatalogChip(
                      label: CatalogNames.of(a),
                      icon: AppIcons.resolve(a.icon),
                      color: a.color == null ? null : Color(a.color!),
                      selected: _pickedActivities.contains(a.id),
                      onTap: () =>
                          setState(() => _pickedActivities.contains(a.id)
                              ? _pickedActivities.remove(a.id)
                              : _pickedActivities.add(a.id)),
                    ),
                  _AddChip(onTap: () => _newActivity(ActivityCategory.rest)),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Color _emotionTone(BuildContext context, EmotionKind kind) =>
      MoodPalette.color(context, kind == EmotionKind.pleasant ? 5 : 2);
}

/// Крупная шкала настроения: пять кружков с подписями.
class _Scale extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onPick;

  const _Scale({required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final m in MoodPaletteX.levels)
          Expanded(
            child: PressableScale(
              child: GestureDetector(
                onTap: () => onPick(m),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: AppTheme.emphasized,
                      width: value == m ? 54 : 44,
                      height: value == m ? 54 : 44,
                      decoration: BoxDecoration(
                        color: MoodPalette.color(context, m),
                        shape: BoxShape.circle,
                        border: value == m
                            ? Border.all(color: scheme.onSurface, width: 2.5)
                            : null,
                      ),
                      child: value == m
                          ? Icon(
                              _faceFor(m),
                              size: 26,
                              color: MoodPalette.on(context, m),
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      MoodPaletteX.label(m),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 11,
                        fontWeight:
                            value == m ? FontWeight.w700 : FontWeight.w500,
                        color: value == m
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _faceFor(int mood) => switch (mood) {
        1 => Icons.sentiment_very_dissatisfied_rounded,
        2 => Icons.sentiment_dissatisfied_rounded,
        3 => Icons.sentiment_neutral_rounded,
        4 => Icons.sentiment_satisfied_rounded,
        _ => Icons.sentiment_very_satisfied_rounded,
      };
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.displayFont,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ChipsWrap extends StatelessWidget {
  final List<Widget> children;
  const _ChipsWrap({required this.children});

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);
}

/// Пилюля эмоции или действия.
class _CatalogChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _CatalogChip({
    required this.label,
    this.icon,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return SizedBox(
      height: 36,
      child: Material(
        color: selected
            ? tint.withValues(alpha: 0.22)
            : scheme.surfaceContainerHigh,
        shape: StadiumBorder(
          side: selected
              ? BorderSide(color: tint, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: icon == null ? 14 : 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: scheme.onSurface),
                  const SizedBox(width: 6),
                ] else ...[
                  Container(
                    width: 9,
                    height: 9,
                    decoration:
                        BoxDecoration(color: tint, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
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

/// «＋ своё» — завести свою эмоцию или действие прямо отсюда.
class _AddChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  tr('own'),
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
