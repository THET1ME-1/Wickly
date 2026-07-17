import 'locale_controller.dart';

/// Перевод строки по ключу на текущий язык интерфейса.
///
/// Каждый ключ хранит переводы на все 7 языков в одном месте — так проще
/// расширять (одна запись = семь языков). Если перевода на выбранный язык нет —
/// откат: английский → русский → сам ключ.
String tr(String key) {
  final code = LocaleController.instance.code;
  final entry = _strings[key];
  if (entry == null) return key;
  return entry[code] ?? entry['en'] ?? entry['ru'] ?? key;
}

/// Перевод с подстановкой `{name}` → значение.
String trf(String key, Map<String, Object> params) {
  var s = tr(key);
  params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Словарь интерфейсных строк. Порядок языков в каждой записи:
/// ru · en · de · fr · es · it · pt.
const Map<String, Map<String, String>> _strings = {
  // ------------------------------ Общее ------------------------------
  'cancel': {
    'ru': 'Отмена', 'en': 'Cancel', 'de': 'Abbrechen', 'fr': 'Annuler',
    'es': 'Cancelar', 'it': 'Annulla', 'pt': 'Cancelar',
  },
  'save': {
    'ru': 'Сохранить', 'en': 'Save', 'de': 'Speichern', 'fr': 'Enregistrer',
    'es': 'Guardar', 'it': 'Salva', 'pt': 'Salvar',
  },
  'reset': {
    'ru': 'Сбросить', 'en': 'Reset', 'de': 'Zurücksetzen', 'fr': 'Réinitialiser',
    'es': 'Restablecer', 'it': 'Reimposta', 'pt': 'Redefinir',
  },
  'apply': {
    'ru': 'Применить', 'en': 'Apply', 'de': 'Übernehmen', 'fr': 'Appliquer',
    'es': 'Aplicar', 'it': 'Applica', 'pt': 'Aplicar',
  },
  'done': {
    'ru': 'Готово', 'en': 'Done', 'de': 'Fertig', 'fr': 'Terminé',
    'es': 'Listo', 'it': 'Fatto', 'pt': 'Concluído',
  },
  'close': {
    'ru': 'Закрыть', 'en': 'Close', 'de': 'Schließen', 'fr': 'Fermer',
    'es': 'Cerrar', 'it': 'Chiudi', 'pt': 'Fechar',
  },

  // ------------------------------ Главная ------------------------------
  'tagline': {
    'ru': 'Дневник, который принадлежит только тебе',
    'en': 'A journal that belongs only to you',
    'de': 'Ein Tagebuch, das nur dir gehört',
    'fr': 'Un journal qui n’appartient qu’à toi',
    'es': 'Un diario que solo te pertenece a ti',
    'it': 'Un diario che appartiene solo a te',
    'pt': 'Um diário que pertence só a você',
  },
  'home_empty_title': {
    'ru': 'Здесь будут твои записи',
    'en': 'Your entries will live here',
    'de': 'Hier entstehen deine Einträge',
    'fr': 'Tes entrées apparaîtront ici',
    'es': 'Aquí estarán tus entradas',
    'it': 'Qui appariranno le tue voci',
    'pt': 'Aqui ficarão suas anotações',
  },
  'home_empty_sub': {
    'ru': 'Первая запись впереди',
    'en': 'The first one is ahead',
    'de': 'Der erste kommt noch',
    'fr': 'La première t’attend',
    'es': 'La primera está por llegar',
    'it': 'La prima è in arrivo',
    'pt': 'A primeira está por vir',
  },
  'new_entry': {
    'ru': 'Новая запись', 'en': 'New entry', 'de': 'Neuer Eintrag',
    'fr': 'Nouvelle entrée', 'es': 'Nueva entrada', 'it': 'Nuova voce',
    'pt': 'Nova anotação',
  },
  'journal_default': {
    'ru': 'Личное', 'en': 'Personal', 'de': 'Persönlich', 'fr': 'Personnel',
    'es': 'Personal', 'it': 'Personale', 'pt': 'Pessoal',
  },

  // ------------------------------ Настройки ------------------------------
  'settings': {
    'ru': 'Настройки', 'en': 'Settings', 'de': 'Einstellungen',
    'fr': 'Paramètres', 'es': 'Ajustes', 'it': 'Impostazioni',
    'pt': 'Configurações',
  },

  // --------------------------- Оформление ---------------------------
  'appearance': {
    'ru': 'Оформление', 'en': 'Appearance', 'de': 'Darstellung',
    'fr': 'Apparence', 'es': 'Apariencia', 'it': 'Aspetto', 'pt': 'Aparência',
  },
  'theme': {
    'ru': 'Тема', 'en': 'Theme', 'de': 'Design', 'fr': 'Thème',
    'es': 'Tema', 'it': 'Tema', 'pt': 'Tema',
  },
  'theme_sheet_title': {
    'ru': 'Тема оформления', 'en': 'App theme', 'de': 'App-Design',
    'fr': 'Thème de l’app', 'es': 'Tema de la app', 'it': 'Tema dell’app',
    'pt': 'Tema do app',
  },
  'theme_light': {
    'ru': 'Светлая', 'en': 'Light', 'de': 'Hell', 'fr': 'Clair',
    'es': 'Claro', 'it': 'Chiaro', 'pt': 'Claro',
  },
  'theme_dark': {
    'ru': 'Тёмная', 'en': 'Dark', 'de': 'Dunkel', 'fr': 'Sombre',
    'es': 'Oscuro', 'it': 'Scuro', 'pt': 'Escuro',
  },
  'theme_system': {
    'ru': 'Как в системе', 'en': 'System', 'de': 'Systemstandard',
    'fr': 'Système', 'es': 'Sistema', 'it': 'Sistema', 'pt': 'Sistema',
  },
  'theme_auto': {
    'ru': 'По времени суток', 'en': 'By time of day', 'de': 'Nach Tageszeit',
    'fr': 'Selon l’heure', 'es': 'Según la hora', 'it': 'In base all’ora',
    'pt': 'Conforme a hora',
  },
  'amoled': {
    'ru': 'AMOLED', 'en': 'AMOLED', 'de': 'AMOLED', 'fr': 'AMOLED',
    'es': 'AMOLED', 'it': 'AMOLED', 'pt': 'AMOLED',
  },
  'amoled_sub': {
    'ru': 'Чистый чёрный фон в тёмной теме',
    'en': 'Pure black background in dark theme',
    'de': 'Reiner schwarzer Hintergrund im dunklen Design',
    'fr': 'Fond noir pur en thème sombre',
    'es': 'Fondo negro puro en el tema oscuro',
    'it': 'Sfondo nero puro nel tema scuro',
    'pt': 'Fundo preto puro no tema escuro',
  },
  'material_you': {
    'ru': 'Material You', 'en': 'Material You', 'de': 'Material You',
    'fr': 'Material You', 'es': 'Material You', 'it': 'Material You',
    'pt': 'Material You',
  },
  'material_you_sub': {
    'ru': 'Цвет из обоев системы (Android 12+)',
    'en': 'Color from your wallpaper (Android 12+)',
    'de': 'Farbe aus dem Hintergrundbild (Android 12+)',
    'fr': 'Couleur du fond d’écran (Android 12+)',
    'es': 'Color del fondo de pantalla (Android 12+)',
    'it': 'Colore dallo sfondo (Android 12+)',
    'pt': 'Cor do papel de parede (Android 12+)',
  },
  'theme_color': {
    'ru': 'Цвет оформления', 'en': 'Accent color', 'de': 'Akzentfarbe',
    'fr': 'Couleur d’accent', 'es': 'Color de acento', 'it': 'Colore d’accento',
    'pt': 'Cor de destaque',
  },
  'theme_color_default': {
    'ru': 'Стандартный', 'en': 'Default', 'de': 'Standard', 'fr': 'Par défaut',
    'es': 'Predeterminado', 'it': 'Predefinito', 'pt': 'Padrão',
  },
  'presets': {
    'ru': 'Палитры', 'en': 'Presets', 'de': 'Paletten', 'fr': 'Palettes',
    'es': 'Paletas', 'it': 'Palette', 'pt': 'Paletas',
  },
  'custom_color': {
    'ru': 'Свой цвет', 'en': 'Custom color', 'de': 'Eigene Farbe',
    'fr': 'Couleur personnalisée', 'es': 'Color propio',
    'it': 'Colore personalizzato', 'pt': 'Cor personalizada',
  },

  // ------------------------------ Язык ------------------------------
  'language': {
    'ru': 'Язык', 'en': 'Language', 'de': 'Sprache', 'fr': 'Langue',
    'es': 'Idioma', 'it': 'Lingua', 'pt': 'Idioma',
  },
  'language_sheet_title': {
    'ru': 'Язык интерфейса', 'en': 'App language', 'de': 'App-Sprache',
    'fr': 'Langue de l’app', 'es': 'Idioma de la app', 'it': 'Lingua dell’app',
    'pt': 'Idioma do app',
  },

  // --------------------------- О программе ---------------------------
  'about': {
    'ru': 'О программе', 'en': 'About', 'de': 'Über', 'fr': 'À propos',
    'es': 'Acerca de', 'it': 'Info', 'pt': 'Sobre',
  },
  'open_source': {
    'ru': 'Открытый код', 'en': 'Open source', 'de': 'Open Source',
    'fr': 'Open source', 'es': 'Código abierto', 'it': 'Open source',
    'pt': 'Código aberto',
  },
  'about_sub': {
    'ru': 'Wickly {v} · GPL-3.0, без рекламы и трекеров',
    'en': 'Wickly {v} · GPL-3.0, no ads or trackers',
    'de': 'Wickly {v} · GPL-3.0, ohne Werbung und Tracker',
    'fr': 'Wickly {v} · GPL-3.0, sans pub ni traceurs',
    'es': 'Wickly {v} · GPL-3.0, sin anuncios ni rastreadores',
    'it': 'Wickly {v} · GPL-3.0, senza pubblicità né tracker',
    'pt': 'Wickly {v} · GPL-3.0, sem anúncios ou rastreadores',
  },
  'source_code': {
    'ru': 'Исходный код на GitHub', 'en': 'Source code on GitHub',
    'de': 'Quellcode auf GitHub', 'fr': 'Code source sur GitHub',
    'es': 'Código fuente en GitHub', 'it': 'Codice sorgente su GitHub',
    'pt': 'Código-fonte no GitHub',
  },
};
