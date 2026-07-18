import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/media_thumb.dart';
import '../widgets/pressable.dart';

/// Место на карте: несколько записей, снятых рядом.
class MapPlace {
  final String title;
  final double lat;
  final double lon;
  final List<Entry> entries;

  const MapPlace({
    required this.title,
    required this.lat,
    required this.lon,
    required this.entries,
  });

  LatLng get point => LatLng(lat, lon);

  Entry get latest => entries.first;

  /// Настроение места — среднее по его записям.
  int? get mood {
    final moods = entries.map((e) => e.mood).whereType<int>().toList();
    if (moods.isEmpty) return null;
    return (moods.reduce((a, b) => a + b) / moods.length).round();
  }

  /// Какая погода бывает тут чаще всего.
  String? get commonWeather {
    final counts = <String, int>{};
    for (final e in entries) {
      final w = e.weather;
      if (w != null) counts[w] = (counts[w] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

/// Карта записей: где что происходило.
///
/// Точки складываются в места: десять записей с одной набережной — одна метка,
/// иначе карта превращается в кашу. Снизу карточка выбранного места.
class MapView extends StatefulWidget {
  final List<MapPlace> places;

  /// Обложка записи по её id — для карточки выбранного места.
  final Map<String, Media> covers;

  final void Function(MapPlace place)? onOpenPlace;
  final VoidCallback? onSearch;

  const MapView({
    super.key,
    required this.places,
    this.covers = const {},
    this.onOpenPlace,
    this.onSearch,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  MapPlace? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.places.isNotEmpty) _selected = widget.places.first;
  }

  LatLng get _center {
    if (widget.places.isEmpty) return const LatLng(59.9386, 30.3141);
    final lat = widget.places.map((p) => p.lat).reduce((a, b) => a + b) /
        widget.places.length;
    final lon = widget.places.map((p) => p.lon).reduce((a, b) => a + b) /
        widget.places.length;
    return LatLng(lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.places.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _SearchBar(onTap: widget.onSearch),
              Expanded(
                child: EmptyState(
                  icon: Icons.map_rounded,
                  title: tr('map_empty_title'),
                  subtitle: tr('map_empty_sub'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              backgroundColor: scheme.surfaceContainerLow,
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              _Tiles(dark: Theme.of(context).brightness == Brightness.dark),
              MarkerLayer(
                markers: [
                  for (final place in widget.places)
                    Marker(
                      point: place.point,
                      width: 34,
                      height: 34,
                      child: _Pin(
                        place: place,
                        selected: place == _selected,
                        onTap: () => setState(() => _selected = place),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Column(
              children: [
                _SearchBar(onTap: widget.onSearch),
                const Spacer(),
                if (_selected != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        WicklyDesign.screenPad, 0, WicklyDesign.screenPad, 12),
                    child: _PlaceCard(
                      place: _selected!,
                      cover: widget.covers[_selected!.latest.id],
                      onTap: () => widget.onOpenPlace?.call(_selected!),
                    ),
                  ),
              ],
            ),
          ),
          // Тонкая рамка снизу, чтобы карта не «вытекала» под навигацию.
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Слой тайлов OpenStreetMap.
///
/// В тёмной теме карта приглушается фильтром: белые улицы посреди ночного
/// интерфейса слепят, а рисовать свой тёмный стиль ради дневника избыточно.
class _Tiles extends StatelessWidget {
  final bool dark;
  const _Tiles({required this.dark});

  @override
  Widget build(BuildContext context) {
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.wickly',
      // Тайлы едут из сети. Без неё остаётся фон схемы, а метки и карточка
      // места работают как обычно.
      errorTileCallback: _ignoreTileError,
    );
    if (!dark) return tiles;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.6, 0, 0, 0, 220, //
        0, -0.6, 0, 0, 215, //
        0, 0, -0.6, 0, 205, //
        0, 0, 0, 1, 0, //
      ]),
      child: tiles,
    );
  }
}

void _ignoreTileError(TileImage tile, Object error, StackTrace? stack) {}

/// Поле поиска поверх карты.
class _SearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  const _SearchBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WicklyDesign.screenPad, 10, WicklyDesign.screenPad, 0),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusField),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('map_search'),
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(Icons.layers_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Метка места: кружок акцента с белой серединой, у выбранного — крупнее.
class _Pin extends StatelessWidget {
  final MapPlace place;
  final bool selected;
  final VoidCallback onTap;

  const _Pin({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = selected ? 30.0 : 24.0;
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: AppTheme.emphasized,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.onPrimary, width: 2),
          ),
          child: Center(
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: scheme.onPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка места снизу: сколько записей, когда была последняя, какая погода.
class _PlaceCard extends StatelessWidget {
  final MapPlace place;

  /// Снимок последней записи места. Без него карточка рисовала один
  /// градиент-заглушку: фото в неё просто не передавали.
  final Media? cover;

  final VoidCallback? onTap;

  const _PlaceCard({required this.place, this.cover, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weather = place.commonWeather;

    return PressableScale(
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: MediaThumb(
                      media: cover,
                      coverKey: CoverPalette.forSeed(place.latest.id),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.title,
                        // Адреса длинные: в одну строку от них оставался
                        // огрызок вроде «Vagias 28, Gazi 714 14, Г…».
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${Dates.entryCount(place.entries.length)} · '
                        '${trf('map_last_entry', {
                              'when': Dates.relativeDay(
                                  place.latest.entryDate),
                            })}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (weather != null || place.mood != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (weather != null)
                              Container(
                                height: 26,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  trf('map_mostly', {'what': weather}),
                                  style: TextStyle(
                                    fontFamily: AppTheme.bodyFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (place.mood != null)
                              MoodDot(mood: place.mood, size: 12),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Обложка для каждой записи — первое наглядное вложение.
///
/// Карта раньше не получала вложений вовсе и рисовала градиент вместо фото.
Map<String, Media> coversByEntry(List<Media> media) {
  final out = <String, Media>{};
  for (final m in media) {
    if (!m.isVisual) continue;
    final current = out[m.entryId];
    // Обложка записи лежит с отрицательным порядком — она и должна победить.
    if (current == null || m.sort < current.sort) out[m.entryId] = m;
  }
  return out;
}

/// Складывает записи с координатами в места.
///
/// Точки в пределах ~150 м считаем одним местом: у телефонного GPS разброс
/// именно такого порядка, и без склейки одна набережная даёт двадцать меток.
List<MapPlace> groupIntoPlaces(List<Entry> entries) {
  const cell = 0.0015; // ~150 м по широте
  final buckets = <String, List<Entry>>{};

  for (final e in entries) {
    if (!e.hasPlace) continue;
    final key = '${(e.lat! / cell).round()}:${(e.lon! / cell).round()}';
    (buckets[key] ??= []).add(e);
  }

  final places = <MapPlace>[];
  for (final group in buckets.values) {
    group.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    final lat = group.map((e) => e.lat!).reduce((a, b) => a + b) / group.length;
    final lon = group.map((e) => e.lon!).reduce((a, b) => a + b) / group.length;
    final named = group.firstWhere(
      (e) => (e.place ?? '').isNotEmpty,
      orElse: () => group.first,
    );
    places.add(MapPlace(
      title: named.place ?? tr('map_unnamed_place'),
      lat: lat,
      lon: lon,
      entries: group,
    ));
  }

  places.sort((a, b) => b.entries.length.compareTo(a.entries.length));
  return places;
}
