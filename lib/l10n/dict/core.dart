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
  'backup_remind': {
    'ru': 'Напоминать о копии', 'en': 'Remind about backups',
    'de': 'An Sicherungen erinnern', 'fr': 'Rappeler les sauvegardes',
    'es': 'Recordar las copias', 'it': 'Ricorda i backup',
    'pt': 'Lembrar das cópias',
  },
  'backup_remind_sub': {
    'ru': 'Копия шифруется твоей фразой, поэтому сделать её автоматически '
        'нельзя — но можно не забыть.',
    'en': 'A backup is sealed with your own phrase, so it cannot be made '
        'automatically — but you can be reminded.',
    'de': 'Die Sicherung wird mit deiner Phrase verschlüsselt und kann daher '
        'nicht automatisch entstehen — aber du wirst erinnert.',
    'fr': 'La sauvegarde est scellée par ta phrase : impossible de la faire '
        'automatiquement, mais on peut te le rappeler.',
    'es': 'La copia se cifra con tu frase, así que no puede hacerse sola — '
        'pero podemos recordártelo.',
    'it': 'Il backup è cifrato con la tua frase, quindi non può essere '
        'automatico — ma possiamo ricordartelo.',
    'pt': 'A cópia é cifrada com a tua frase, por isso não pode ser feita '
        'sozinha — mas dá para lembrar.',
  },
  'backup_none_yet': {
    'ru': 'Резервной копии ещё не было',
    'en': 'You have never made a backup',
    'de': 'Es gibt noch keine Sicherung',
    'fr': 'Aucune sauvegarde pour l’instant',
    'es': 'Todavía no hay ninguna copia',
    'it': 'Non c’è ancora nessun backup',
    'pt': 'Ainda não há nenhuma cópia',
  },
  'backup_stale': {
    'ru': 'Последней копии {n} дней. Дневник живёт на одном устройстве.',
    'en': 'The last backup is {n} days old. The journal lives on one device.',
    'de': 'Die letzte Sicherung ist {n} Tage alt. Das Tagebuch liegt auf einem Gerät.',
    'fr': 'La dernière sauvegarde date de {n} jours. Le journal tient sur un seul appareil.',
    'es': 'La última copia tiene {n} días. El diario vive en un solo dispositivo.',
    'it': 'L’ultimo backup ha {n} giorni. Il diario vive su un solo dispositivo.',
    'pt': 'A última cópia tem {n} dias. O diário vive num só aparelho.',
  },
  'update_new_version': {
    'ru': 'Новая {v}', 'en': 'New {v}', 'de': 'Neu {v}', 'fr': 'Nouvelle {v}',
    'es': 'Nueva {v}', 'it': 'Nuova {v}', 'pt': 'Nova {v}',
  },
  'update_current_version': {
    'ru': 'у тебя {v}', 'en': 'you have {v}', 'de': 'du hast {v}',
    'fr': 'tu as {v}', 'es': 'tienes {v}', 'it': 'hai {v}',
    'pt': 'tens {v}',
  },
  'update_downloading': {
    'ru': 'Скачиваем… {p}%', 'en': 'Downloading… {p}%',
    'de': 'Wird geladen… {p}%', 'fr': 'Téléchargement… {p}%',
    'es': 'Descargando… {p}%', 'it': 'Scaricamento… {p}%',
    'pt': 'A transferir… {p}%',
  },
  'print': {
    'ru': 'Печать', 'en': 'Print', 'de': 'Drucken', 'fr': 'Imprimer',
    'es': 'Imprimir', 'it': 'Stampa', 'pt': 'Imprimir',
  },
  'print_sub': {
    'ru': 'Книга на принтер или в PDF через систему',
    'en': 'Send the book to a printer or system PDF',
    'de': 'Das Buch an den Drucker oder als System-PDF',
    'fr': 'Le livre vers l’imprimante ou en PDF système',
    'es': 'El libro a la impresora o a PDF del sistema',
    'it': 'Il libro in stampa o in PDF di sistema',
    'pt': 'O livro para a impressora ou PDF do sistema',
  },
  'haptics': {
    'ru': 'Отклик', 'en': 'Haptics', 'de': 'Haptik', 'fr': 'Retour haptique',
    'es': 'Vibración', 'it': 'Feedback aptico', 'pt': 'Vibração',
  },
  'haptics_sub': {
    'ru': 'Короткая вибрация на действия',
    'en': 'A short buzz on your actions',
    'de': 'Kurze Vibration bei Aktionen',
    'fr': 'Une brève vibration sur tes gestes',
    'es': 'Una vibración breve al actuar',
    'it': 'Una breve vibrazione sulle azioni',
    'pt': 'Uma vibração curta nas ações',
  },
  'lock_timeout': {
    'ru': 'Запирать', 'en': 'Lock after', 'de': 'Sperren nach',
    'fr': 'Verrouiller après', 'es': 'Bloquear tras',
    'it': 'Blocca dopo', 'pt': 'Bloquear após',
  },
  'lock_timeout_now': {
    'ru': 'Сразу', 'en': 'Immediately', 'de': 'Sofort', 'fr': 'Aussitôt',
    'es': 'Al instante', 'it': 'Subito', 'pt': 'De imediato',
  },
  'lock_timeout_min': {
    'ru': 'Через {n} мин', 'en': 'After {n} min', 'de': 'Nach {n} Min',
    'fr': 'Après {n} min', 'es': 'Tras {n} min', 'it': 'Dopo {n} min',
    'pt': 'Após {n} min',
  },
  'theme_intensity': {
    'ru': 'Насыщенность', 'en': 'Intensity', 'de': 'Intensität',
    'fr': 'Intensité', 'es': 'Intensidad', 'it': 'Intensità',
    'pt': 'Intensidade',
  },
  'theme_vibrant': {
    'ru': 'Сочно', 'en': 'Vibrant', 'de': 'Kräftig', 'fr': 'Vif',
    'es': 'Vivo', 'it': 'Vivace', 'pt': 'Vibrante',
  },
  'theme_faithful': {
    'ru': 'Точь-в-точь', 'en': 'Faithful', 'de': 'Originalgetreu',
    'fr': 'Fidèle', 'es': 'Fiel', 'it': 'Fedele', 'pt': 'Fiel',
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

  'favorites': {
    'ru': 'Избранное', 'en': 'Favorites', 'de': 'Favoriten', 'fr': 'Favoris',
    'es': 'Favoritos', 'it': 'Preferiti', 'pt': 'Favoritos',
  },
  'prev_month': {
    'ru': 'Прошлый месяц', 'en': 'Previous month', 'de': 'Voriger Monat',
    'fr': 'Mois précédent', 'es': 'Mes anterior', 'it': 'Mese precedente',
    'pt': 'Mês anterior',
  },
  'next_month': {
    'ru': 'Следующий месяц', 'en': 'Next month', 'de': 'Nächster Monat',
    'fr': 'Mois suivant', 'es': 'Mes siguiente', 'it': 'Mese successivo',
    'pt': 'Próximo mês',
  },
  'synced': {
    'ru': 'Синхронизировано', 'en': 'Synced', 'de': 'Synchronisiert',
    'fr': 'Synchronisé', 'es': 'Sincronizado', 'it': 'Sincronizzato',
    'pt': 'Sincronizado',
  },
  'sync_never': {
    'ru': 'Ещё не синхронизировано', 'en': 'Not synced yet',
    'de': 'Noch nicht synchronisiert', 'fr': 'Pas encore synchronisé',
    'es': 'Aún sin sincronizar', 'it': 'Non ancora sincronizzato',
    'pt': 'Ainda não sincronizado',
  },
  'tags': {
    'ru': 'Теги', 'en': 'Tags', 'de': 'Tags', 'fr': 'Étiquettes',
    'es': 'Etiquetas', 'it': 'Tag', 'pt': 'Tags',
  },
  'days_short': {
    'ru': '{n} дн.', 'en': '{n} d', 'de': '{n} T.', 'fr': '{n} j',
    'es': '{n} d', 'it': '{n} gg', 'pt': '{n} d',
  },
  'day_mood': {
    'ru': 'Как день', 'en': 'How the day went', 'de': 'Wie der Tag war',
    'fr': 'La journée', 'es': 'Cómo fue el día', 'it': 'Com’è andata',
    'pt': 'Como foi o dia',
  },
  'write_on_day': {
    'ru': 'Записать этим днём', 'en': 'Write for this day',
    'de': 'Für diesen Tag schreiben', 'fr': 'Écrire pour ce jour',
    'es': 'Escribir para ese día', 'it': 'Scrivi per questo giorno',
    'pt': 'Escrever para esse dia',
  },
  'write_on_day_sub': {
    'ru': 'задним числом, без потери порядка',
    'en': 'backdated, order stays intact',
    'de': 'rückdatiert, die Reihenfolge bleibt',
    'fr': 'antidaté, l’ordre est conservé',
    'es': 'con fecha anterior, sin romper el orden',
    'it': 'retrodatato, l’ordine resta',
    'pt': 'com data anterior, sem quebrar a ordem',
  },
  'month_written': {
    'ru': 'записано {a} из {b}', 'en': 'written {a} of {b}',
    'de': '{a} von {b} beschrieben', 'fr': '{a} jours écrits sur {b}',
    'es': 'escritos {a} de {b}', 'it': 'scritti {a} su {b}',
    'pt': 'escritos {a} de {b}',
  },
  'month_words': {
    'ru': 'слов за месяц', 'en': 'words this month', 'de': 'Wörter im Monat',
    'fr': 'mots ce mois', 'es': 'palabras del mes', 'it': 'parole nel mese',
    'pt': 'palavras no mês',
  },
  'days_written': {
    'ru': 'дней с записью', 'en': 'days with an entry',
    'de': 'Tage mit Eintrag', 'fr': 'jours avec une entrée',
    'es': 'días con anotación', 'it': 'giorni con una voce',
    'pt': 'dias com anotação',
  },
  'days_in_row': {
    'ru': 'дней подряд', 'en': 'days in a row', 'de': 'Tage in Folge',
    'fr': 'jours d’affilée', 'es': 'días seguidos', 'it': 'giorni di fila',
    'pt': 'dias seguidos',
  },
  'mood_average': {
    'ru': 'среднее настроение', 'en': 'average mood',
    'de': 'durchschnittliche Stimmung', 'fr': 'humeur moyenne',
    'es': 'ánimo medio', 'it': 'umore medio', 'pt': 'humor médio',
  },
  'filter_all': {
    'ru': 'Все', 'en': 'All', 'de': 'Alle', 'fr': 'Tout', 'es': 'Todo',
    'it': 'Tutte', 'pt': 'Todas',
  },
  'filter_photo': {
    'ru': 'С фото', 'en': 'With photos', 'de': 'Mit Fotos',
    'fr': 'Avec photos', 'es': 'Con fotos', 'it': 'Con foto',
    'pt': 'Com fotos',
  },
  'desktop_layout': {
    'ru': 'Раскладка', 'en': 'Layout', 'de': 'Anordnung', 'fr': 'Disposition',
    'es': 'Disposición', 'it': 'Disposizione', 'pt': 'Disposição',
  },
  'layout_board': {
    'ru': 'Стол', 'en': 'Board', 'de': 'Tisch', 'fr': 'Table',
    'es': 'Mesa', 'it': 'Tavolo', 'pt': 'Mesa',
  },
  'layout_board_sub': {
    'ru': 'доска записей, дневники слева, сегодня справа',
    'en': 'a board of entries, journals on the left, today on the right',
    'de': 'Pinnwand mit Einträgen, Tagebücher links, Heute rechts',
    'fr': 'un tableau d’entrées, journaux à gauche, aujourd’hui à droite',
    'es': 'tablero de anotaciones, diarios a la izquierda, hoy a la derecha',
    'it': 'bacheca di voci, diari a sinistra, oggi a destra',
    'pt': 'quadro de anotações, diários à esquerda, hoje à direita',
  },
  'layout_spread': {
    'ru': 'Разворот', 'en': 'Spread', 'de': 'Doppelseite', 'fr': 'Double page',
    'es': 'Doble página', 'it': 'Doppia pagina', 'pt': 'Página dupla',
  },
  'layout_spread_sub': {
    'ru': 'список слева, запись во всю высоту справа',
    'en': 'the list on the left, the entry full height on the right',
    'de': 'Liste links, Eintrag rechts in voller Höhe',
    'fr': 'la liste à gauche, l’entrée en pleine hauteur à droite',
    'es': 'la lista a la izquierda, la anotación a toda altura a la derecha',
    'it': 'elenco a sinistra, voce a tutta altezza a destra',
    'pt': 'a lista à esquerda, a anotação em altura total à direita',
  },
  'layout_chronicle': {
    'ru': 'Хроника', 'en': 'Chronicle', 'de': 'Chronik', 'fr': 'Chronique',
    'es': 'Crónica', 'it': 'Cronaca', 'pt': 'Crônica',
  },
  'layout_chronicle_sub': {
    'ru': 'месяц цветом настроения, записи дня рядом',
    'en': 'the month coloured by mood, the day’s entries beside it',
    'de': 'der Monat in Stimmungsfarben, die Einträge des Tages daneben',
    'fr': 'le mois coloré par l’humeur, les entrées du jour à côté',
    'es': 'el mes coloreado por el ánimo, las anotaciones del día al lado',
    'it': 'il mese colorato dall’umore, le voci del giorno accanto',
    'pt': 'o mês colorido pelo humor, as anotações do dia ao lado',
  },

  // ---------------------------- Десктоп ----------------------------
  'desktop': {
    'ru': 'Широкое окно', 'en': 'Wide window', 'de': 'Breites Fenster',
    'fr': 'Fenêtre large', 'es': 'Ventana ancha', 'it': 'Finestra larga',
    'pt': 'Janela larga',
  },
  'rail_collapse': {
    'ru': 'Свернуть меню', 'en': 'Collapse the menu',
    'de': 'Menü einklappen', 'fr': 'Réduire le menu',
    'es': 'Contraer el menú', 'it': 'Comprimi il menu',
    'pt': 'Recolher o menu',
  },
  'rail_expand': {
    'ru': 'Развернуть меню', 'en': 'Expand the menu',
    'de': 'Menü ausklappen', 'fr': 'Déployer le menu',
    'es': 'Expandir el menú', 'it': 'Espandi il menu',
    'pt': 'Expandir o menu',
  },
  'view_grid': {
    'ru': 'Кладкой', 'en': 'As a board', 'de': 'Als Pinnwand',
    'fr': 'En tableau', 'es': 'En tablero', 'it': 'A bacheca',
    'pt': 'Em quadro',
  },
  'view_list': {
    'ru': 'Списком по дням', 'en': 'As a list by day',
    'de': 'Als Liste nach Tagen', 'fr': 'En liste par jour',
    'es': 'En lista por días', 'it': 'A elenco per giorni',
    'pt': 'Em lista por dias',
  },
  'feed_columns': {
    'ru': 'Записей в ряду', 'en': 'Entries per row',
    'de': 'Einträge pro Reihe', 'fr': 'Entrées par rangée',
    'es': 'Anotaciones por fila', 'it': 'Voci per riga',
    'pt': 'Anotações por linha',
  },
  'feed_columns_auto': {
    'ru': 'По ширине окна', 'en': 'Fit the window',
    'de': 'Nach Fensterbreite', 'fr': 'Selon la largeur',
    'es': 'Según el ancho', 'it': 'In base alla larghezza',
    'pt': 'Conforme a largura',
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
    'ru': 'свой пароль на вход в этот дневник',
    'en': 'a separate password for this journal',
    'de': 'ein eigenes Passwort für dieses Tagebuch',
    'fr': 'un mot de passe propre à ce journal',
    'es': 'una contraseña propia para este diario',
    'it': 'una password dedicata a questo diario',
    'pt': 'uma senha própria para este diário',
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
  'update_available': {'ru': 'Доступно обновление', 'en': 'Update available',
    'de': 'Update verfügbar',
    'fr': 'Mise à jour disponible',
    'es': 'Actualización disponible',
    'it': 'Aggiornamento disponibile',
    'pt': 'Atualização disponível',
  },
  'update_whats_new': {'ru': 'Что нового', 'en': "What's new",
    'de': 'Was ist neu',
    'fr': 'Quoi de neuf',
    'es': 'Qué hay de nuevo',
    'it': 'Cosa c’è di nuovo',
    'pt': 'O que há de novo',
  },
  'update_installing': {'ru': 'Запуск установки…', 'en': 'Starting install…',
    'de': 'Installation wird gestartet…',
    'fr': 'Démarrage de l’installation…',
    'es': 'Iniciando la instalación…',
    'it': 'Avvio dell’installazione…',
    'pt': 'Iniciando a instalação…',
  },
  'update_failed': {'ru': 'Не удалось скачать. Откройте релиз вручную.',
    'en': 'Download failed. Open the release manually.',
    'de': 'Update fehlgeschlagen',
    'fr': 'La mise à jour a échoué',
    'es': 'La actualización falló',
    'it': 'Aggiornamento fallito',
    'pt': 'A atualização falhou',
  },
  'update_open_github': {'ru': 'Открыть на GitHub', 'en': 'Open on GitHub',
    'de': 'Auf GitHub öffnen',
    'fr': 'Ouvrir sur GitHub',
    'es': 'Abrir en GitHub',
    'it': 'Apri su GitHub',
    'pt': 'Abrir no GitHub',
  },
  'update_later': {'ru': 'Позже', 'en': 'Later',
    'de': 'Später',
    'fr': 'Plus tard',
    'es': 'Más tarde',
    'it': 'Più tardi',
    'pt': 'Mais tarde',
  },
  'update_now': {'ru': 'Обновить', 'en': 'Update',
    'de': 'Aktualisieren',
    'fr': 'Mettre à jour',
    'es': 'Actualizar',
    'it': 'Aggiorna',
    'pt': 'Atualizar',
  },
  'update_check_failed': {'ru': 'Не удалось проверить обновления',
    'en': 'Could not check for updates',
    'de': 'Prüfen fehlgeschlagen',
    'fr': 'Vérification impossible',
    'es': 'No se pudo comprobar',
    'it': 'Controllo non riuscito',
    'pt': 'Não foi possível verificar',
  },
  'update_check': {
    'ru': 'Проверить обновления', 'en': 'Check for updates',
    'de': 'Auf Updates prüfen', 'fr': 'Vérifier les mises à jour',
    'es': 'Buscar actualizaciones', 'it': 'Cerca aggiornamenti',
    'pt': 'Buscar atualizações',
  },
  'update_latest': {
    'ru': 'Установлена последняя версия', 'en': 'You are on the latest version',
    'de': 'Du hast die neueste Version', 'fr': 'Tu as la dernière version',
    'es': 'Tienes la última versión', 'it': 'Hai l’ultima versione',
    'pt': 'Você está na última versão',
  },
};
