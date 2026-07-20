import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../l10n/strings.dart';
import '../models/catalog.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';
import '../theme/icon_keys.dart';
import '../utils/catalog_names.dart';
import 'color_picker_sheet.dart';
import 'icon_picker_sheet.dart';
import 'sheet_scaffold.dart';

/// Заводит или правит свою эмоцию.
Future<Emotion?> showEmotionEditor(
  BuildContext context, {
  Emotion? emotion,
  EmotionKind kind = EmotionKind.pleasant,
}) =>
    showWicklySheet<Emotion>(
      context,
      builder: (_) => _CatalogEditor(
        title: emotion == null ? tr('new_emotion') : CatalogNames.of(emotion),
        initialName: emotion == null ? '' : CatalogNames.of(emotion),
        initialIcon: emotion?.icon ?? 'star',
        initialColor: emotion?.color,
        groups: [
          _Group('pleasant', tr('pleasant')),
          _Group('hard', tr('hard')),
        ],
        initialGroup: (emotion?.kind ?? kind).name,
        onSave: (name, icon, color, group) async {
          final repo = CatalogRepository.instance;
          final saved = emotion == null
              ? Emotion.create(
                  name: name,
                  kind: EmotionKind.parse(group),
                  icon: icon,
                  color: color,
                )
              : emotion.copyWith(
                  name: name,
                  kind: EmotionKind.parse(group),
                  icon: icon,
                  color: color,
                );
          if (emotion == null) {
            await repo.insertEmotion(saved);
          } else {
            await repo.updateEmotion(saved);
          }
          return saved;
        },
      ),
    );

/// Заводит или правит своё действие.
Future<Activity?> showActivityEditor(
  BuildContext context, {
  Activity? activity,
  ActivityCategory category = ActivityCategory.rest,
}) =>
    showWicklySheet<Activity>(
      context,
      builder: (_) => _CatalogEditor(
        title: activity == null ? tr('new_activity') : CatalogNames.of(activity),
        initialName: activity == null ? '' : CatalogNames.of(activity),
        initialIcon: activity?.icon ?? 'star',
        initialColor: activity?.color,
        groups: [
          _Group('people', tr('cat_people')),
          _Group('body', tr('cat_body')),
          _Group('home', tr('cat_home')),
          _Group('rest', tr('cat_rest')),
        ],
        initialGroup: (activity?.category ?? category).name,
        onSave: (name, icon, color, group) async {
          final repo = CatalogRepository.instance;
          final saved = activity == null
              ? Activity.create(
                  name: name,
                  category: ActivityCategory.parse(group),
                  icon: icon,
                  color: color,
                )
              : activity.copyWith(
                  name: name,
                  category: ActivityCategory.parse(group),
                  icon: icon,
                  color: color,
                );
          if (activity == null) {
            await repo.insertActivity(saved);
          } else {
            await repo.updateActivity(saved);
          }
          return saved;
        },
      ),
    );

class _Group {
  final String key;
  final String label;
  const _Group(this.key, this.label);
}

/// «Создать своё»: имя, иконка, цвет и группа.
///
/// Один лист и для эмоции, и для действия, и для правки готового — набор полей
/// у них одинаковый, а разное приезжает параметрами.
class _CatalogEditor<T> extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialIcon;
  final int? initialColor;
  final List<_Group> groups;
  final String initialGroup;
  final Future<T> Function(
    String name,
    String icon,
    int? color,
    String group,
  ) onSave;

  const _CatalogEditor({
    required this.title,
    required this.initialName,
    required this.initialIcon,
    required this.initialColor,
    required this.groups,
    required this.initialGroup,
    required this.onSave,
  });

  @override
  State<_CatalogEditor<T>> createState() => _CatalogEditorState<T>();
}

class _CatalogEditorState<T> extends State<_CatalogEditor<T>> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  late String _icon = widget.initialIcon;
  late int? _color = widget.initialColor;
  late String _group = widget.initialGroup;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    final picked = await showColorPickerSheet(
      context,
      initial: _color == null ? kWicklyPresets.first : Color(_color!),
      title: tr('custom_color'),
      cancelLabel: tr('cancel'),
      applyLabel: tr('apply'),
      resetLabel: tr('reset'),
    );
    if (picked != null) setState(() => _color = picked.toARGB32());
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final saved = await widget.onSave(name, _icon, _color, _group);
    if (mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = _color == null ? scheme.primary : Color(_color!);

    return SheetScaffold(
      action: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      bottom: FilledButton(onPressed: _save, child: Text(tr('save'))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Крупный предпросмотр: видно, как элемент будет выглядеть в списке.
            Center(
              child: Column(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: tint, width: 2),
                    ),
                    child: Icon(AppIcons.resolve(_icon),
                        size: 30, color: tint),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _name.text.trim().isEmpty ? widget.title : _name.text.trim(),
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              autofocus: widget.initialName.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: tr('name')),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            _Label(tr('icon')),
            IconChoiceGrid(
              selected: _icon,
              tint: tint,
              onPick: (key) => setState(() => _icon = key),
            ),
            const SizedBox(height: 18),
            _Label(tr('color')),
            Row(
              children: [
                for (final c in kWicklyPresets.take(5)) ...[
                  _ColorCell(
                    color: c,
                    selected: _color == c.toARGB32(),
                    onTap: () => setState(() => _color = c.toARGB32()),
                  ),
                  const SizedBox(width: 10),
                ],
                _ColorCell(
                  color: null,
                  selected: false,
                  onTap: _pickColor,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Label(tr('category')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in widget.groups)
                  ChoiceChip(
                    label: Text(g.label),
                    selected: _group == g.key,
                    onSelected: (_) => setState(() => _group = g.key),
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _group == g.key
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                    selectedColor: scheme.primaryContainer,
                    backgroundColor: scheme.surfaceContainerHigh,
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
}

class _ColorCell extends StatelessWidget {
  /// `null` — ячейка «свой цвет» с колор-пикером.
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorCell({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color ?? scheme.surfaceContainerHigh,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: color == null
            ? Icon(Icons.add_rounded, size: 18, color: scheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}
