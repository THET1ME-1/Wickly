import 'package:flutter/material.dart';

/// Единый реестр иконок, на которые ссылаются данные (эмоции, действия,
/// трекеры, обложки дневников).
///
/// В базе лежит **строковый ключ**, а не код иконки: так набор переживает
/// обновления Flutter, синкается между устройствами и не ломает tree-shaking
/// (все `IconData` перечислены здесь константами).
///
/// Ключи **только дописываем**. Переименование или удаление осиротит записи,
/// заведённые прошлыми версиями и приехавшие по синку: `resolve` отдаст им
/// [fallback], и у человека на экране молча сменится значок.
class AppIcons {
  const AppIcons._();

  static const fallback = Icons.circle_outlined;

  // ── Группы ────────────────────────────────────────────────────────────────
  // Порядок внутри группы = порядок в сетке выбора. Названия групп живут не
  // здесь, а в `widgets/icon_picker_sheet.dart`: слой темы про словарь не знает.

  static const List<String> people = [
    'people', 'person', 'family', 'baby', 'elderly', 'friends',
    'heart', 'chat', 'call', 'mail', 'handshake', 'care',
    'hello', 'face', 'pets', 'group',
  ];

  static const List<String> feelings = [
    'joy', 'smile', 'neutral', 'upset', 'grief', 'heart_broken',
    'calm', 'spa', 'mind', 'energy', 'flame', 'sparkle',
    'holiday', 'thumb_up', 'thumb_down', 'star',
  ];

  static const List<String> body = [
    'sport', 'pulse', 'walk', 'steps', 'sleep', 'water',
    'bike', 'swim', 'hike', 'ski', 'ball', 'basket',
    'tennis', 'pill', 'doctor', 'weight',
    'shower', 'hands', 'sick', 'vaccine',
  ];

  static const List<String> food = [
    'cooking', 'coffee', 'tea', 'breakfast', 'lunch', 'dinner',
    'fastfood', 'pizza', 'ramen', 'bakery', 'bowl', 'egg',
    'cake', 'icecream', 'wine', 'beer', 'cocktail', 'juice',
  ];

  static const List<String> household = [
    'home', 'clean', 'laundry', 'iron', 'bed', 'chair',
    'kitchen', 'bath', 'door', 'key', 'tools', 'repair',
    'shopping', 'cart', 'plant', 'trash',
  ];

  static const List<String> work = [
    'work', 'laptop', 'code', 'meeting', 'school', 'science',
    'chart', 'task', 'calendar', 'timer', 'money', 'savings',
    'badge', 'language', 'print', 'folder',
  ];

  static const List<String> leisure = [
    'movie', 'tv', 'music', 'headphones', 'mic', 'piano',
    'game', 'puzzle', 'casino', 'theater', 'podcast', 'book',
    'palette', 'brush', 'camera', 'photo', 'fishing', 'garden',
  ];

  static const List<String> outdoors = [
    'nature', 'forest', 'leaf', 'flower', 'mountain', 'beach',
    'waves', 'sun', 'sunset', 'moon', 'night', 'cloud',
    'rain', 'snow', 'storm', 'wind',
  ];

  static const List<String> journey = [
    'travel', 'place', 'map', 'explore', 'car', 'bus',
    'train', 'ship', 'hotel', 'tent', 'luggage', 'city',
    'museum', 'temple', 'ticket', 'road',
  ];

  static const List<String> symbols = [
    'gift', 'idea', 'check', 'flag', 'bookmark', 'label',
    'lock', 'shield', 'bell', 'clock', 'forever', 'diamond',
    'award', 'rocket', 'anchor', 'pen',
    'note', 'question', 'warning', 'no_phone', 'more',
  ];

  /// Все иконки одним списком — порядок групп задаёт сетку выбора.
  static const List<List<String>> groups = [
    people, feelings, body, food, household,
    work, leisure, outdoors, journey, symbols,
  ];

  /// Что показываем сразу в редакторе, не открывая полный список.
  /// Первые шестнадцать — самые ходовые: их же берут редакторы дневника и
  /// трекера, поэтому вставлять новое в начало нельзя.
  static const List<String> pickerOrder = [
    'sport', 'pulse', 'heart', 'book', 'movie', 'music',
    'coffee', 'cooking', 'pen', 'people', 'place', 'walk',
    'sleep', 'water', 'steps', 'work', 'shopping', 'home',
    'star', 'sun', 'moon', 'nature', 'travel', 'game',
    'camera', 'leaf', 'flame', 'gift', 'idea', 'calm',
    'no_phone', 'more',
  ];

  static const Map<String, IconData> all = {
    // Люди
    'people': Icons.people_alt_rounded,
    'person': Icons.person_rounded,
    'family': Icons.family_restroom_rounded,
    'baby': Icons.child_care_rounded,
    'elderly': Icons.elderly_rounded,
    'friends': Icons.diversity_3_rounded,
    'heart': Icons.favorite_rounded,
    'chat': Icons.forum_rounded,
    'call': Icons.call_rounded,
    'mail': Icons.mail_rounded,
    'handshake': Icons.handshake_rounded,
    'care': Icons.volunteer_activism_rounded,
    'hello': Icons.waving_hand_rounded,
    'face': Icons.face_rounded,
    'pets': Icons.pets_rounded,
    'group': Icons.groups_rounded,

    // Чувства
    'joy': Icons.sentiment_very_satisfied_rounded,
    'smile': Icons.sentiment_satisfied_rounded,
    'neutral': Icons.sentiment_neutral_rounded,
    'upset': Icons.sentiment_dissatisfied_rounded,
    'grief': Icons.sentiment_very_dissatisfied_rounded,
    'heart_broken': Icons.heart_broken_rounded,
    'calm': Icons.self_improvement_rounded,
    'spa': Icons.spa_rounded,
    'mind': Icons.psychology_rounded,
    'energy': Icons.bolt_rounded,
    'flame': Icons.local_fire_department_rounded,
    'sparkle': Icons.auto_awesome_rounded,
    'holiday': Icons.celebration_rounded,
    'thumb_up': Icons.thumb_up_rounded,
    'thumb_down': Icons.thumb_down_rounded,
    'star': Icons.star_rounded,

    // Тело
    'sport': Icons.fitness_center_rounded,
    'pulse': Icons.monitor_heart_rounded,
    'walk': Icons.directions_walk_rounded,
    'steps': Icons.directions_run_rounded,
    'sleep': Icons.bedtime_rounded,
    'water': Icons.water_drop_rounded,
    'bike': Icons.directions_bike_rounded,
    'swim': Icons.pool_rounded,
    'hike': Icons.hiking_rounded,
    'ski': Icons.downhill_skiing_rounded,
    'ball': Icons.sports_soccer_rounded,
    'basket': Icons.sports_basketball_rounded,
    'tennis': Icons.sports_tennis_rounded,
    'pill': Icons.medication_rounded,
    'doctor': Icons.medical_services_rounded,
    'weight': Icons.monitor_weight_rounded,
    'shower': Icons.shower_rounded,
    'hands': Icons.clean_hands_rounded,
    'sick': Icons.sick_rounded,
    'vaccine': Icons.vaccines_rounded,

    // Еда
    'cooking': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'tea': Icons.emoji_food_beverage_rounded,
    'breakfast': Icons.free_breakfast_rounded,
    'lunch': Icons.lunch_dining_rounded,
    'dinner': Icons.dinner_dining_rounded,
    'fastfood': Icons.fastfood_rounded,
    'pizza': Icons.local_pizza_rounded,
    'ramen': Icons.ramen_dining_rounded,
    'bakery': Icons.bakery_dining_rounded,
    'bowl': Icons.rice_bowl_rounded,
    'egg': Icons.egg_alt_rounded,
    'cake': Icons.cake_rounded,
    'icecream': Icons.icecream_rounded,
    'wine': Icons.wine_bar_rounded,
    'beer': Icons.sports_bar_rounded,
    'cocktail': Icons.local_bar_rounded,
    'juice': Icons.local_drink_rounded,

    // Дом и дела
    'home': Icons.home_rounded,
    'clean': Icons.cleaning_services_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'iron': Icons.iron_rounded,
    'bed': Icons.bed_rounded,
    'chair': Icons.chair_rounded,
    'kitchen': Icons.kitchen_rounded,
    'bath': Icons.bathtub_rounded,
    'door': Icons.door_front_door_rounded,
    'key': Icons.key_rounded,
    'tools': Icons.handyman_rounded,
    'repair': Icons.build_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'cart': Icons.shopping_cart_rounded,
    'plant': Icons.grass_rounded,
    'trash': Icons.delete_rounded,

    // Работа и учёба
    'work': Icons.work_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'code': Icons.code_rounded,
    'meeting': Icons.co_present_rounded,
    'school': Icons.school_rounded,
    'science': Icons.science_rounded,
    'chart': Icons.insights_rounded,
    'task': Icons.task_alt_rounded,
    'calendar': Icons.event_rounded,
    'timer': Icons.timer_rounded,
    'money': Icons.payments_rounded,
    'savings': Icons.savings_rounded,
    'badge': Icons.badge_rounded,
    'language': Icons.translate_rounded,
    'print': Icons.print_rounded,
    'folder': Icons.folder_rounded,

    // Отдых
    'movie': Icons.movie_rounded,
    'tv': Icons.tv_rounded,
    'music': Icons.music_note_rounded,
    'headphones': Icons.headphones_rounded,
    'mic': Icons.mic_rounded,
    'piano': Icons.piano_rounded,
    'game': Icons.sports_esports_rounded,
    'puzzle': Icons.extension_rounded,
    'casino': Icons.casino_rounded,
    'theater': Icons.theater_comedy_rounded,
    'podcast': Icons.podcasts_rounded,
    'book': Icons.menu_book_rounded,
    'palette': Icons.palette_rounded,
    'brush': Icons.brush_rounded,
    'camera': Icons.photo_camera_rounded,
    'photo': Icons.photo_rounded,
    // `phishing` в Material — удочка с леской, рыбалка читается верно.
    'fishing': Icons.phishing_rounded,
    'garden': Icons.yard_rounded,

    // Природа
    'nature': Icons.park_rounded,
    'forest': Icons.forest_rounded,
    'leaf': Icons.eco_rounded,
    'flower': Icons.local_florist_rounded,
    'mountain': Icons.landscape_rounded,
    'beach': Icons.beach_access_rounded,
    'waves': Icons.waves_rounded,
    'sun': Icons.wb_sunny_rounded,
    'sunset': Icons.wb_twilight_rounded,
    'moon': Icons.nightlight_round,
    'night': Icons.nights_stay_rounded,
    'cloud': Icons.cloud_rounded,
    'rain': Icons.umbrella_rounded,
    'snow': Icons.ac_unit_rounded,
    'storm': Icons.thunderstorm_rounded,
    'wind': Icons.air_rounded,

    // Дорога
    'travel': Icons.flight_rounded,
    'place': Icons.place_rounded,
    'map': Icons.map_rounded,
    'explore': Icons.explore_rounded,
    'car': Icons.directions_car_rounded,
    'bus': Icons.directions_bus_rounded,
    'train': Icons.train_rounded,
    'ship': Icons.directions_boat_rounded,
    'hotel': Icons.hotel_rounded,
    'tent': Icons.cabin_rounded,
    'luggage': Icons.luggage_rounded,
    'city': Icons.location_city_rounded,
    'museum': Icons.museum_rounded,
    'temple': Icons.temple_buddhist_rounded,
    'ticket': Icons.confirmation_number_rounded,
    'road': Icons.route_rounded,

    // Символы
    'gift': Icons.card_giftcard_rounded,
    'idea': Icons.lightbulb_rounded,
    'check': Icons.check_circle_rounded,
    'flag': Icons.flag_rounded,
    'bookmark': Icons.bookmark_rounded,
    'label': Icons.label_rounded,
    'lock': Icons.lock_rounded,
    'shield': Icons.shield_rounded,
    'bell': Icons.notifications_rounded,
    'clock': Icons.schedule_rounded,
    'forever': Icons.all_inclusive_rounded,
    'diamond': Icons.diamond_rounded,
    'award': Icons.workspace_premium_rounded,
    'rocket': Icons.rocket_launch_rounded,
    'anchor': Icons.anchor_rounded,
    'pen': Icons.edit_rounded,
    'note': Icons.sticky_note_2_rounded,
    'question': Icons.help_rounded,
    'warning': Icons.warning_rounded,
    'no_phone': Icons.phonelink_erase_rounded,
    'more': Icons.more_horiz_rounded,
  };

  static IconData resolve(String? key) => all[key] ?? fallback;
}
