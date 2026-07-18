/// Общие строки, главный экран, настройки, оформление, язык, «о программе».
///
/// Одна запись = семь языков (ru · en · de · fr · es · it · pt) — так словарь
/// расширяется одной правкой, а не семью.
library;

const Map<String, Map<String, String>> coreStrings = {
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

  'today': {
    'ru': 'сегодня', 'en': 'today', 'de': 'heute', 'fr': 'aujourd’hui',
    'es': 'hoy', 'it': 'oggi', 'pt': 'hoje',
  },
  'yesterday': {
    'ru': 'вчера', 'en': 'yesterday', 'de': 'gestern', 'fr': 'hier',
    'es': 'ayer', 'it': 'ieri', 'pt': 'ontem',
  },
  'delete': {
    'ru': 'Удалить', 'en': 'Delete', 'de': 'Löschen', 'fr': 'Supprimer',
    'es': 'Eliminar', 'it': 'Elimina', 'pt': 'Excluir',
  },
  'edit': {
    'ru': 'Изменить', 'en': 'Edit', 'de': 'Bearbeiten', 'fr': 'Modifier',
    'es': 'Editar', 'it': 'Modifica', 'pt': 'Editar',
  },
  'back': {
    'ru': 'Назад', 'en': 'Back', 'de': 'Zurück', 'fr': 'Retour',
    'es': 'Atrás', 'it': 'Indietro', 'pt': 'Voltar',
  },
  'search': {
    'ru': 'Поиск', 'en': 'Search', 'de': 'Suche', 'fr': 'Recherche',
    'es': 'Buscar', 'it': 'Cerca', 'pt': 'Buscar',
  },
  'add': {
    'ru': 'Добавить', 'en': 'Add', 'de': 'Hinzufügen', 'fr': 'Ajouter',
    'es': 'Añadir', 'it': 'Aggiungi', 'pt': 'Adicionar',
  },
  'mood_1': {
    'ru': 'Плохо', 'en': 'Rough', 'de': 'Schlecht', 'fr': 'Mauvais',
    'es': 'Mal', 'it': 'Male', 'pt': 'Ruim',
  },
  'mood_2': {
    'ru': 'Так себе', 'en': 'Meh', 'de': 'Geht so', 'fr': 'Bof',
    'es': 'Regular', 'it': 'Così così', 'pt': 'Mais ou menos',
  },
  'mood_3': {
    'ru': 'Норм', 'en': 'Okay', 'de': 'Okay', 'fr': 'Correct',
    'es': 'Normal', 'it': 'Normale', 'pt': 'Normal',
  },
  'mood_4': {
    'ru': 'Хорошо', 'en': 'Good', 'de': 'Gut', 'fr': 'Bien',
    'es': 'Bien', 'it': 'Bene', 'pt': 'Bem',
  },
  'mood_5': {
    'ru': 'Отлично', 'en': 'Great', 'de': 'Super', 'fr': 'Super',
    'es': 'Genial', 'it': 'Ottimo', 'pt': 'Ótimo',
  },

  'section_journal': {
    'ru': 'Дневник', 'en': 'Journal', 'de': 'Tagebuch', 'fr': 'Journal',
    'es': 'Diario', 'it': 'Diario', 'pt': 'Diário',
  },
  'section_privacy': {
    'ru': 'Приватность', 'en': 'Privacy', 'de': 'Privatsphäre',
    'fr': 'Confidentialité', 'es': 'Privacidad', 'it': 'Privacy',
    'pt': 'Privacidade',
  },
  'section_data': {
    'ru': 'Данные', 'en': 'Data', 'de': 'Daten', 'fr': 'Données',
    'es': 'Datos', 'it': 'Dati', 'pt': 'Dados',
  },
  'journals_and_covers': {
    'ru': 'Дневники и обложки', 'en': 'Journals and covers',
    'de': 'Tagebücher und Cover', 'fr': 'Journaux et couvertures',
    'es': 'Diarios y portadas', 'it': 'Diari e copertine',
    'pt': 'Diários e capas',
  },
  'reminders_and_prompts': {
    'ru': 'Напоминания и подсказки', 'en': 'Reminders and prompts',
    'de': 'Erinnerungen und Fragen', 'fr': 'Rappels et questions',
    'es': 'Recordatorios y preguntas', 'it': 'Promemoria e domande',
    'pt': 'Lembretes e perguntas',
  },
  'lock': {
    'ru': 'Замок', 'en': 'Lock', 'de': 'Sperre', 'fr': 'Verrou',
    'es': 'Bloqueo', 'it': 'Blocco', 'pt': 'Trava',
  },
  'lock_sub': {
    'ru': 'PIN и отпечаток', 'en': 'PIN and fingerprint',
    'de': 'PIN und Fingerabdruck', 'fr': 'PIN et empreinte',
    'es': 'PIN y huella', 'it': 'PIN e impronta', 'pt': 'PIN e digital',
  },
  'hidden_entries': {
    'ru': 'Скрытые записи', 'en': 'Hidden entries',
    'de': 'Verborgene Einträge', 'fr': 'Entrées masquées',
    'es': 'Entradas ocultas', 'it': 'Voci nascoste',
    'pt': 'Anotações ocultas',
  },
  'hidden_entries_sub': {
    'ru': 'не видны в ленте, календаре и поиске',
    'en': 'invisible in the feed, calendar and search',
    'de': 'nicht im Verlauf, Kalender und in der Suche',
    'fr': 'invisibles dans le fil, le calendrier et la recherche',
    'es': 'no aparecen en el muro, calendario ni búsqueda',
    'it': 'non compaiono nel diario, nel calendario e nella ricerca',
    'pt': 'não aparecem na linha, calendário nem busca',
  },
  'hidden_empty_title': {
    'ru': 'Скрытых записей нет', 'en': 'No hidden entries',
    'de': 'Keine verborgenen Einträge', 'fr': 'Aucune entrée masquée',
    'es': 'No hay entradas ocultas', 'it': 'Nessuna voce nascosta',
    'pt': 'Sem anotações ocultas',
  },
  'hidden_empty_sub': {
    'ru': 'Скрыть запись можно из меню в самой записи',
    'en': 'You can hide an entry from its own menu',
    'de': 'Einen Eintrag verbirgst du in seinem eigenen Menü',
    'fr': 'On masque une entrée depuis son propre menu',
    'es': 'Puedes ocultar una entrada desde su propio menú',
    'it': 'Puoi nascondere una voce dal suo menu',
    'pt': 'Você pode ocultar uma anotação pelo menu dela',
  },
  'auto_context': {
    'ru': 'Место и погода', 'en': 'Place and weather', 'de': 'Ort und Wetter',
    'fr': 'Lieu et météo', 'es': 'Lugar y clima', 'it': 'Luogo e meteo',
    'pt': 'Lugar e clima',
  },
  'auto_context_sub': {
    'ru': 'подставлять в новую запись',
    'en': 'fill them into a new entry',
    'de': 'in neue Einträge einsetzen',
    'fr': 'les ajouter aux nouvelles entrées',
    'es': 'añadirlos a la entrada nueva',
    'it': 'inserirli nella nuova voce',
    'pt': 'preencher na nova anotação',
  },
  'sync_sub': {
    'ru': 'между своими устройствами', 'en': 'between your own devices',
    'de': 'zwischen deinen Geräten', 'fr': 'entre tes appareils',
    'es': 'entre tus dispositivos', 'it': 'tra i tuoi dispositivi',
    'pt': 'entre seus aparelhos',
  },
  'appearance_sub': {
    'ru': 'тема, цвет, размер текста', 'en': 'theme, colour, text size',
    'de': 'Design, Farbe, Textgröße', 'fr': 'thème, couleur, taille du texte',
    'es': 'tema, color, tamaño del texto', 'it': 'tema, colore, dimensione',
    'pt': 'tema, cor, tamanho do texto',
  },
  'text_size': {
    'ru': 'Размер текста', 'en': 'Text size', 'de': 'Textgröße',
    'fr': 'Taille du texte', 'es': 'Tamaño del texto',
    'it': 'Dimensione del testo', 'pt': 'Tamanho do texto',
  },
  'text_size_sample': {
    'ru': 'Дошли до старого моста, вода ещё тёплая.',
    'en': 'We walked to the old bridge, the water was still warm.',
    'de': 'Wir liefen bis zur alten Brücke, das Wasser war noch warm.',
    'fr': 'On a marché jusqu’au vieux pont, l’eau était encore tiède.',
    'es': 'Llegamos al puente viejo, el agua seguía tibia.',
    'it': 'Siamo arrivati al vecchio ponte, l’acqua era ancora tiepida.',
    'pt': 'Chegamos à ponte velha, a água ainda estava morna.',
  },
  'start_screen': {
    'ru': 'Стартовый экран', 'en': 'Start screen', 'de': 'Startbildschirm',
    'fr': 'Écran de départ', 'es': 'Pantalla inicial',
    'it': 'Schermata iniziale', 'pt': 'Tela inicial',
  },
  'cover': {
    'ru': 'Обложка', 'en': 'Cover', 'de': 'Cover', 'fr': 'Couverture',
    'es': 'Portada', 'it': 'Copertina', 'pt': 'Capa',
  },
  'unit': {
    'ru': 'Единица', 'en': 'Unit', 'de': 'Einheit', 'fr': 'Unité',
    'es': 'Unidad', 'it': 'Unità', 'pt': 'Unidade',
  },
  'journal_lock': {
    'ru': 'Под паролем', 'en': 'Password protected', 'de': 'Mit Passwort',
    'fr': 'Protégé par mot de passe', 'es': 'Con contraseña',
    'it': 'Protetto da password', 'pt': 'Com senha',
  },
  'journal_lock_sub': {
    'ru': 'спрашивать код при входе в этот дневник',
    'en': 'ask for the code when opening this journal',
    'de': 'beim Öffnen dieses Tagebuchs nach dem Code fragen',
    'fr': 'demander le code à l’ouverture de ce journal',
    'es': 'pedir el código al abrir este diario',
    'it': 'chiedere il codice all’apertura di questo diario',
    'pt': 'pedir o código ao abrir este diário',
  },
  'delete_journal_q': {
    'ru': 'Удалить дневник «{name}» вместе со всеми его записями?',
    'en': 'Delete the journal “{name}” with all of its entries?',
    'de': 'Tagebuch „{name}“ mit allen Einträgen löschen?',
    'fr': 'Supprimer le journal « {name} » avec toutes ses entrées ?',
    'es': '¿Eliminar el diario «{name}» con todas sus entradas?',
    'it': 'Eliminare il diario «{name}» con tutte le sue voci?',
    'pt': 'Excluir o diário “{name}” com todas as anotações?',
  },
};
