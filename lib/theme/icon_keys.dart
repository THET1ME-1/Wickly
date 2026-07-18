import 'package:flutter/material.dart';

/// Единый реестр иконок, на которые ссылаются данные (эмоции, действия,
/// трекеры, обложки дневников).
///
/// В базе лежит **строковый ключ**, а не код иконки: так набор переживает
/// обновления Flutter, синкается между устройствами и не ломает tree-shaking
/// (все `IconData` перечислены здесь константами).
class AppIcons {
  const AppIcons._();

  static const fallback = Icons.circle_outlined;

  static const Map<String, IconData> all = {
    // Люди
    'people': Icons.people_alt_rounded,
    'home': Icons.home_rounded,
    'heart': Icons.favorite_rounded,
    'chat': Icons.forum_rounded,
    // Тело
    'sport': Icons.fitness_center_rounded,
    'pulse': Icons.monitor_heart_rounded,
    'walk': Icons.directions_walk_rounded,
    'sleep': Icons.bedtime_rounded,
    'water': Icons.water_drop_rounded,
    'steps': Icons.directions_run_rounded,
    // Дом и дела
    'cooking': Icons.restaurant_rounded,
    'work': Icons.work_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'clean': Icons.cleaning_services_rounded,
    // Отдых
    'coffee': Icons.local_cafe_rounded,
    'movie': Icons.movie_rounded,
    'book': Icons.menu_book_rounded,
    'music': Icons.music_note_rounded,
    'game': Icons.sports_esports_rounded,
    'travel': Icons.flight_rounded,
    'nature': Icons.park_rounded,
    // Общее
    'star': Icons.star_rounded,
    'sun': Icons.wb_sunny_rounded,
    'moon': Icons.nightlight_round,
    'place': Icons.place_rounded,
    'camera': Icons.photo_camera_rounded,
    'pen': Icons.edit_rounded,
    'leaf': Icons.eco_rounded,
    'flame': Icons.local_fire_department_rounded,
    'gift': Icons.card_giftcard_rounded,
    'idea': Icons.lightbulb_rounded,
    'calm': Icons.self_improvement_rounded,
    'no_phone': Icons.phonelink_erase_rounded,
    'more': Icons.more_horiz_rounded,
  };

  /// Порядок показа в выборе иконки (сетка на экране «Создать своё»).
  static const List<String> pickerOrder = [
    'sport', 'pulse', 'heart', 'book', 'movie', 'music',
    'coffee', 'cooking', 'pen', 'people', 'place', 'walk',
    'sleep', 'water', 'steps', 'work', 'shopping', 'home',
    'star', 'sun', 'moon', 'nature', 'travel', 'game',
    'camera', 'leaf', 'flame', 'gift', 'idea', 'calm',
    'no_phone', 'more',
  ];

  static IconData resolve(String? key) => all[key] ?? fallback;
}
