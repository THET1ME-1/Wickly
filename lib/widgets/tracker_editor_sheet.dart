import 'package:flutter/material.dart';

import '../data/tracker_repository.dart';
import '../l10n/strings.dart';
import '../models/catalog.dart';
import '../theme/app_theme.dart';
import '../theme/icon_keys.dart';
import '../utils/catalog_names.dart';
import 'sheet_scaffold.dart';

/// Заводит или правит трекер: имя, вид, цель, единица и иконка.
Future<Tracker?> showTrackerEditor(
  BuildContext context, {
  Tracker? tracker,
  int sort = 0,
}) =>
    showWicklySheet<Tracker>(
      context,
      builder: (_) => _TrackerEditor(tracker: tracker, sort: sort),
    );

class _TrackerEditor extends StatefulWidget {
  final Tracker? tracker;
  final int sort;

  const _TrackerEditor({this.tracker, required this.sort});

  @override
  State<_TrackerEditor> createState() => _TrackerEditorState();
}

class _TrackerEditorState extends State<_TrackerEditor> {
  late final TextEditingController _name = TextEditingController(
      text: widget.tracker == null ? '' : CatalogNames.of(widget.tracker!));
  late final TextEditingController _unit =
      TextEditingController(text: _unitLabel(widget.tracker));
  late final TextEditingController _goal = TextEditingController(
      text: widget.tracker?.goal == null
          ? ''
          : _short(widget.tracker!.goal!));

  late TrackerKind _kind = widget.tracker?.kind ?? TrackerKind.number;
  late String _icon = widget.tracker?.icon ?? 'star';

  static String _unitLabel(Tracker? t) {
    final unit = t?.unit;
    if (unit == null) return '';
    return hasTr(unit) ? tr(unit) : unit;
  }

  static String _short(double v) =>
      v % 1 == 0 ? '${v.toInt()}' : v.toStringAsFixed(1);

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final repo = TrackerRepository.instance;
    // У привычки цель всегда «сделал один раз»: спрашивать её бессмысленно.
    final goal = _kind == TrackerKind.habit
        ? 1.0
        : double.tryParse(_goal.text.trim().replaceAll(',', '.'));

    final saved = widget.tracker == null
        ? Tracker.create(
            name: name,
            kind: _kind,
            unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
            goal: goal,
            icon: _icon,
            sort: widget.sort,
          )
        : widget.tracker!.copyWith(
            name: name,
            kind: _kind,
            unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
            goal: goal,
            icon: _icon,
          );
    if (widget.tracker == null) {
      await repo.insert(saved);
    } else {
      await repo.update(saved);
    }
    if (mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _delete() async {
    final tracker = widget.tracker;
    if (tracker == null) return;
    await TrackerRepository.instance.delete(tracker.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    TextStyle label() => TextStyle(
          fontFamily: AppTheme.displayFont,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: scheme.onSurface,
        );

    return SheetScaffold(
      title: widget.tracker == null ? tr('new_tracker') : tr('edit'),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      action: widget.tracker == null
          ? null
          : IconButton(
              icon: Icon(Icons.delete_rounded, color: scheme.error),
              onPressed: _delete,
            ),
      bottom: FilledButton(onPressed: _save, child: Text(tr('save'))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.tracker == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: tr('name')),
            ),
            const SizedBox(height: 16),
            Text(tr('tracker_kind'), style: label()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final k in TrackerKind.values)
                  ChoiceChip(
                    label: Text(switch (k) {
                      TrackerKind.number => tr('kind_number'),
                      TrackerKind.duration => tr('kind_duration'),
                      TrackerKind.habit => tr('kind_habit'),
                    }),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                    showCheckmark: false,
                    selectedColor: scheme.primaryContainer,
                    backgroundColor: scheme.surfaceContainerHigh,
                  ),
              ],
            ),
            if (_kind != TrackerKind.habit) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goal,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: tr('tracker_goal')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unit,
                      decoration: InputDecoration(labelText: tr('unit')),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(tr('icon'), style: label()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in AppIcons.pickerOrder.take(20))
                  GestureDetector(
                    onTap: () => setState(() => _icon = key),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _icon == key
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        AppIcons.resolve(key),
                        size: 20,
                        color: _icon == key
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
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
