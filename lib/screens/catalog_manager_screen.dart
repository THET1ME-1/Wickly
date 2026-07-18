import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../l10n/strings.dart';
import '../models/catalog.dart';
import '../theme/app_theme.dart';
import '../theme/icon_keys.dart';
import '../theme/wickly_design.dart';
import '../utils/catalog_names.dart';
import '../widgets/catalog_editor_sheet.dart';

/// Менеджер эмоций и действий.
///
/// Списком, а не сеткой: здесь важен порядок — он определяет, что человек
/// увидит первым при отметке настроения. Перетаскивание меняет порядок,
/// карандаш открывает правку, свайп убирает из каталога.
class CatalogManagerScreen extends StatefulWidget {
  /// Открыть сразу вкладку действий.
  final bool startWithActivities;

  const CatalogManagerScreen({super.key, this.startWithActivities = false});

  @override
  State<CatalogManagerScreen> createState() => _CatalogManagerScreenState();
}

class _CatalogManagerScreenState extends State<CatalogManagerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.startWithActivities ? 1 : 0,
  );

  List<Emotion> _emotions = const [];
  List<Activity> _activities = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final emotions = await CatalogRepository.instance.emotions();
    final activities = await CatalogRepository.instance.activities();
    if (!mounted) return;
    setState(() {
      _emotions = emotions;
      _activities = activities;
    });
  }

  Future<void> _create() async {
    if (_tabs.index == 0) {
      await showEmotionEditor(context);
    } else {
      await showActivityEditor(context);
    }
    await _load();
  }

  Future<void> _delete(CatalogItem item) async {
    final name = CatalogNames.of(item);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(trf('delete_from_catalog_q', {'name': name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tr('delete'),
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (item is Emotion) {
      await CatalogRepository.instance.deleteEmotion(item.id);
    } else if (item is Activity) {
      await CatalogRepository.instance.deleteActivity(item.id);
    }
    await _load();
  }

  Future<void> _reorderEmotions(EmotionKind kind, int from, int to) async {
    final group = _emotions.where((e) => e.kind == kind).toList();
    if (to > from) to--;
    final moved = group.removeAt(from);
    group.insert(to, moved);
    // Порядок пересобираем целиком: группы идут подряд, поэтому склеиваем
    // приятные и тяжёлые в один список и нумеруем заново.
    final pleasant = kind == EmotionKind.pleasant
        ? group
        : _emotions.where((e) => e.kind == EmotionKind.pleasant).toList();
    final hard = kind == EmotionKind.hard
        ? group
        : _emotions.where((e) => e.kind == EmotionKind.hard).toList();
    await CatalogRepository.instance
        .reorderEmotions([...pleasant, ...hard].map((e) => e.id).toList());
    await _load();
  }

  Future<void> _reorderActivities(
      ActivityCategory category, int from, int to) async {
    final group = _activities.where((a) => a.category == category).toList();
    if (to > from) to--;
    final moved = group.removeAt(from);
    group.insert(to, moved);
    final all = <Activity>[];
    for (final c in ActivityCategory.values) {
      all.addAll(c == category
          ? group
          : _activities.where((a) => a.category == c));
    }
    await CatalogRepository.instance
        .reorderActivities(all.map((a) => a.id).toList());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('emotions_and_activities')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _create,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Column(
            children: [
              TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: tr('tab_emotions')),
                  Tab(text: tr('tab_activities')),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  tr('drag_to_order'),
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabs.index == 0
            ? tr('create_emotion')
            : tr('create_activity')),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _EmotionsTab(
            emotions: _emotions,
            onReorder: _reorderEmotions,
            onEdit: (e) async {
              await showEmotionEditor(context, emotion: e);
              await _load();
            },
            onDelete: _delete,
          ),
          _ActivitiesTab(
            activities: _activities,
            onReorder: _reorderActivities,
            onEdit: (a) async {
              await showActivityEditor(context, activity: a);
              await _load();
            },
            onDelete: _delete,
          ),
        ],
      ),
    );
  }
}

class _EmotionsTab extends StatelessWidget {
  final List<Emotion> emotions;
  final void Function(EmotionKind kind, int from, int to) onReorder;
  final void Function(Emotion) onEdit;
  final void Function(CatalogItem) onDelete;

  const _EmotionsTab({
    required this.emotions,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          WicklyDesign.screenPad, 4, WicklyDesign.screenPad, 96),
      children: [
        for (final kind in EmotionKind.values) ...[
          _GroupTitle(
            kind == EmotionKind.pleasant ? tr('pleasant') : tr('hard'),
          ),
          _ReorderableGroup(
            length: emotions.where((e) => e.kind == kind).length,
            onReorder: (from, to) => onReorder(kind, from, to),
            itemBuilder: (context, i) {
              final list = emotions.where((e) => e.kind == kind).toList();
              final e = list[i];
              return _CatalogRow(
                key: ValueKey(e.id),
                title: CatalogNames.of(e),
                color: e.color == null
                    ? MoodPalette.color(
                        context, kind == EmotionKind.pleasant ? 5 : 2)
                    : Color(e.color!),
                onEdit: () => onEdit(e),
                onDelete: () => onDelete(e),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ActivitiesTab extends StatelessWidget {
  final List<Activity> activities;
  final void Function(ActivityCategory category, int from, int to) onReorder;
  final void Function(Activity) onEdit;
  final void Function(CatalogItem) onDelete;

  const _ActivitiesTab({
    required this.activities,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  });

  static String _categoryLabel(ActivityCategory c) => switch (c) {
        ActivityCategory.people => tr('cat_people'),
        ActivityCategory.body => tr('cat_body'),
        ActivityCategory.home => tr('cat_home'),
        ActivityCategory.rest => tr('cat_rest'),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          WicklyDesign.screenPad, 4, WicklyDesign.screenPad, 96),
      children: [
        for (final category in ActivityCategory.values) ...[
          _GroupTitle(_categoryLabel(category)),
          _ReorderableGroup(
            length: activities.where((a) => a.category == category).length,
            onReorder: (from, to) => onReorder(category, from, to),
            itemBuilder: (context, i) {
              final list =
                  activities.where((a) => a.category == category).toList();
              final a = list[i];
              return _CatalogRow(
                key: ValueKey(a.id),
                title: CatalogNames.of(a),
                icon: AppIcons.resolve(a.icon),
                color: a.color == null ? scheme.primary : Color(a.color!),
                onEdit: () => onEdit(a),
                onDelete: () => onDelete(a),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Группа с перетаскиванием внутри себя.
class _ReorderableGroup extends StatelessWidget {
  final int length;
  final void Function(int from, int to) onReorder;
  final Widget Function(BuildContext context, int index) itemBuilder;

  const _ReorderableGroup({
    required this.length,
    required this.onReorder,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (length == 0) return const SizedBox(height: 4);
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: length,
      onReorder: onReorder,
      itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
        key: ValueKey('drag-$i-${length}_${itemBuilder(context, i).key}'),
        index: i,
        child: itemBuilder(context, i),
      ),
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.03, child: child),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String title;
  const _GroupTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}

/// Строка каталога: точка или иконка, имя, правка и «ручка» перетаскивания.
class _CatalogRow extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CatalogRow({
    super.key,
    required this.title,
    this.icon,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('dismiss-$title'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          // Строка уезжает только после подтверждения и перезагрузки списка.
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.delete_rounded, color: scheme.onErrorContainer),
        ),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              if (icon != null)
                Icon(icon, size: 18, color: color)
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: scheme.onSurfaceVariant,
                onPressed: onEdit,
              ),
              Icon(Icons.drag_handle_rounded,
                  size: 20, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
