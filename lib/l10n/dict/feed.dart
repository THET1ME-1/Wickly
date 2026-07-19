/// Раздел Б макета: лента, календарь, медиа-сетка, карта.
///
/// Одна запись = семь языков (ru · en · de · fr · es · it · pt).
library;

const Map<String, Map<String, String>> feedStrings = {
  // ------------------------------ Лента ------------------------------
  'tab_feed': {
    'ru': 'Лента', 'en': 'Feed', 'de': 'Verlauf', 'fr': 'Fil',
    'es': 'Muro', 'it': 'Diario', 'pt': 'Linha',
  },
  'tab_calendar': {
    'ru': 'Календарь', 'en': 'Calendar', 'de': 'Kalender', 'fr': 'Calendrier',
    'es': 'Calendario', 'it': 'Calendario', 'pt': 'Calendário',
  },
  'tab_map': {
    'ru': 'Карта', 'en': 'Map', 'de': 'Karte', 'fr': 'Carte',
    'es': 'Mapa', 'it': 'Mappa', 'pt': 'Mapa',
  },
  'tab_media': {
    'ru': 'Медиа', 'en': 'Media', 'de': 'Medien', 'fr': 'Médias',
    'es': 'Medios', 'it': 'Media', 'pt': 'Mídia',
  },
  'tab_more': {
    'ru': 'Ещё', 'en': 'More', 'de': 'Mehr', 'fr': 'Plus',
    'es': 'Más', 'it': 'Altro', 'pt': 'Mais',
  },
  'entry_untitled': {
    'ru': 'Без заголовка', 'en': 'Untitled', 'de': 'Ohne Titel',
    'fr': 'Sans titre', 'es': 'Sin título', 'it': 'Senza titolo',
    'pt': 'Sem título',
  },
  'write': {
    'ru': 'Записать', 'en': 'Write', 'de': 'Schreiben', 'fr': 'Écrire',
    'es': 'Escribir', 'it': 'Scrivi', 'pt': 'Escrever',
  },
  'streak_keep': {
    'ru': 'не прерывай серию', 'en': 'keep the streak going',
    'de': 'halte die Serie', 'fr': 'garde la série',
    'es': 'mantén la racha', 'it': 'non spezzare la serie',
    'pt': 'mantenha a sequência',
  },
  'streak_start': {
    'ru': 'запиши день — начнётся серия',
    'en': 'write today and start a streak',
    'de': 'schreib heute und starte eine Serie',
    'fr': 'écris aujourd’hui et lance une série',
    'es': 'escribe hoy y empieza una racha',
    'it': 'scrivi oggi e inizia una serie',
    'pt': 'escreva hoje e comece uma sequência',
  },
  'on_this_day': {
    'ru': 'В этот день', 'en': 'On this day', 'de': 'An diesem Tag',
    'fr': 'Ce jour-là', 'es': 'En este día', 'it': 'In questo giorno',
    'pt': 'Neste dia',
  },
  'feed_empty_title': {
    'ru': 'Здесь будет твой день',
    'en': 'Your day will be here',
    'de': 'Hier steht dein Tag',
    'fr': 'Ta journée sera ici',
    'es': 'Aquí estará tu día',
    'it': 'Qui ci sarà la tua giornata',
    'pt': 'Aqui ficará o seu dia',
  },
  'feed_empty_sub': {
    'ru': 'Начни с пары строк о сегодняшнем',
    'en': 'Start with a couple of lines about today',
    'de': 'Fang mit zwei Zeilen über heute an',
    'fr': 'Commence par deux lignes sur aujourd’hui',
    'es': 'Empieza con un par de líneas sobre hoy',
    'it': 'Inizia con due righe su oggi',
    'pt': 'Comece com duas linhas sobre hoje',
  },

  // ---------------------------- Календарь ----------------------------
  'mood_of_month': {
    'ru': 'Настроение месяца', 'en': 'Mood this month',
    'de': 'Stimmung des Monats', 'fr': 'Humeur du mois',
    'es': 'Ánimo del mes', 'it': 'Umore del mese',
    'pt': 'Humor do mês',
  },
  'average': {
    'ru': 'среднее', 'en': 'average', 'de': 'Durchschnitt', 'fr': 'moyenne',
    'es': 'promedio', 'it': 'media', 'pt': 'média',
  },
  'streak_short': {
    'ru': 'серия', 'en': 'streak', 'de': 'Serie', 'fr': 'série',
    'es': 'racha', 'it': 'serie', 'pt': 'sequência',
  },
  'most_common': {
    'ru': 'чаще всего', 'en': 'most often', 'de': 'am häufigsten',
    'fr': 'le plus souvent', 'es': 'lo más común', 'it': 'più spesso',
    'pt': 'mais comum',
  },
  'days_of_count': {
    'ru': '{a} из {b} дней', 'en': '{a} of {b} days',
    'de': '{a} von {b} Tagen', 'fr': '{a} jours sur {b}',
    'es': '{a} de {b} días', 'it': '{a} di {b} giorni',
    'pt': '{a} de {b} dias',
  },

  // ------------------------------ Медиа ------------------------------
  'media_all': {
    'ru': 'Все', 'en': 'All', 'de': 'Alle', 'fr': 'Tout',
    'es': 'Todo', 'it': 'Tutti', 'pt': 'Tudo',
  },
  'media_photo': {
    'ru': 'Фото', 'en': 'Photos', 'de': 'Fotos', 'fr': 'Photos',
    'es': 'Fotos', 'it': 'Foto', 'pt': 'Fotos',
  },
  'media_video': {
    'ru': 'Видео', 'en': 'Video', 'de': 'Videos', 'fr': 'Vidéos',
    'es': 'Vídeos', 'it': 'Video', 'pt': 'Vídeos',
  },
  'media_audio': {
    'ru': 'Аудио', 'en': 'Audio', 'de': 'Audio', 'fr': 'Audio',
    'es': 'Audio', 'it': 'Audio', 'pt': 'Áudio',
  },
  'media_count': {
    'ru': '{photo} фото · {video} видео',
    'en': '{photo} photos · {video} videos',
    'de': '{photo} Fotos · {video} Videos',
    'fr': '{photo} photos · {video} vidéos',
    'es': '{photo} fotos · {video} vídeos',
    'it': '{photo} foto · {video} video',
    'pt': '{photo} fotos · {video} vídeos',
  },
  'media_empty_title': {
    'ru': 'Пока нет вложений',
    'en': 'No attachments yet',
    'de': 'Noch keine Anhänge',
    'fr': 'Pas encore de pièces jointes',
    'es': 'Aún no hay adjuntos',
    'it': 'Ancora nessun allegato',
    'pt': 'Ainda sem anexos',
  },
  'media_empty_sub': {
    'ru': 'Фото и голос из записей соберутся здесь',
    'en': 'Photos and voice notes from entries gather here',
    'de': 'Fotos und Sprachnotizen sammeln sich hier',
    'fr': 'Les photos et les notes vocales se rassemblent ici',
    'es': 'Aquí se reúnen fotos y notas de voz',
    'it': 'Qui si raccolgono foto e note vocali',
    'pt': 'Fotos e notas de voz ficam reunidas aqui',
  },

  // ------------------------------ Карта ------------------------------
  'map_search': {
    'ru': 'Искать место или запись', 'en': 'Search a place or entry',
    'de': 'Ort oder Eintrag suchen', 'fr': 'Chercher un lieu ou une entrée',
    'es': 'Buscar un lugar o entrada', 'it': 'Cerca un luogo o una voce',
    'pt': 'Buscar um lugar ou anotação',
  },
  'map_empty_title': {
    'ru': 'Карта пока пустая',
    'en': 'The map is still empty',
    'de': 'Die Karte ist noch leer',
    'fr': 'La carte est encore vide',
    'es': 'El mapa aún está vacío',
    'it': 'La mappa è ancora vuota',
    'pt': 'O mapa ainda está vazio',
  },
  'map_empty_sub': {
    'ru': 'Записи с местом появятся точками',
    'en': 'Entries with a place will show up as pins',
    'de': 'Einträge mit Ort erscheinen als Punkte',
    'fr': 'Les entrées avec un lieu apparaîtront en points',
    'es': 'Las entradas con lugar aparecerán como puntos',
    'it': 'Le voci con un luogo appariranno come punti',
    'pt': 'Anotações com lugar aparecerão como pontos',
  },
  'map_last_entry': {
    'ru': 'последняя {when}', 'en': 'last one {when}',
    'de': 'letzte {when}', 'fr': 'dernière {when}',
    'es': 'última {when}', 'it': 'ultima {when}',
    'pt': 'última {when}',
  },
  'map_mostly': {
    'ru': 'чаще {what}', 'en': 'mostly {what}', 'de': 'meist {what}',
    'fr': 'surtout {what}', 'es': 'sobre todo {what}', 'it': 'per lo più {what}',
    'pt': 'geralmente {what}',
  },

  'map_unnamed_place': {
    'ru': 'Без названия', 'en': 'Unnamed place', 'de': 'Ohne Namen',
    'fr': 'Lieu sans nom', 'es': 'Lugar sin nombre', 'it': 'Luogo senza nome',
    'pt': 'Lugar sem nome',
  },

  // ------------------------- Дневники и поиск -------------------------
  'journals': {
    'ru': 'Дневники', 'en': 'Journals', 'de': 'Tagebücher', 'fr': 'Journaux',
    'es': 'Diarios', 'it': 'Diari', 'pt': 'Diários',
  },
  'new_journal': {
    'ru': 'Новый дневник', 'en': 'New journal', 'de': 'Neues Tagebuch',
    'fr': 'Nouveau journal', 'es': 'Nuevo diario', 'it': 'Nuovo diario',
    'pt': 'Novo diário',
  },
  'journal_locked': {
    'ru': 'под паролем', 'en': 'password protected', 'de': 'mit Passwort',
    'fr': 'protégé par mot de passe', 'es': 'con contraseña',
    'it': 'protetto da password', 'pt': 'com senha',
  },
  'journal_empty_title': {
    'ru': 'В этом дневнике пусто', 'en': 'This journal is empty',
    'de': 'Dieses Tagebuch ist leer', 'fr': 'Ce journal est vide',
    'es': 'Este diario está vacío', 'it': 'Questo diario è vuoto',
    'pt': 'Este diário está vazio',
  },
  'journal_empty_sub': {
    'ru': 'Первая запись начнётся отсюда', 'en': 'The first entry starts here',
    'de': 'Der erste Eintrag beginnt hier',
    'fr': 'La première entrée commence ici',
    'es': 'La primera anotación empieza aquí',
    'it': 'La prima voce inizia qui', 'pt': 'A primeira anotação começa aqui',
  },
  'journal_locked_entry': {
    'ru': 'Запись под паролем', 'en': 'Password-protected entry',
    'de': 'Eintrag mit Passwort', 'fr': 'Entrée protégée par mot de passe',
    'es': 'Anotación con contraseña', 'it': 'Voce protetta da password',
    'pt': 'Anotação com senha',
  },
  'journal_locked_tap': {
    'ru': 'Нажмите, чтобы ввести пароль', 'en': 'Tap to enter the password',
    'de': 'Tippen, um das Passwort einzugeben',
    'fr': 'Touchez pour saisir le mot de passe',
    'es': 'Toca para escribir la contraseña',
    'it': 'Tocca per inserire la password', 'pt': 'Toque para digitar a senha',
  },
  'journal_password': {
    'ru': 'Пароль дневника', 'en': 'Journal password',
    'de': 'Tagebuch-Passwort', 'fr': 'Mot de passe du journal',
    'es': 'Contraseña del diario', 'it': 'Password del diario',
    'pt': 'Senha do diário',
  },
  'journal_password_new': {
    'ru': 'Придумайте пароль', 'en': 'Create a password',
    'de': 'Passwort ausdenken', 'fr': 'Choisissez un mot de passe',
    'es': 'Cree una contraseña', 'it': 'Scegli una password',
    'pt': 'Crie uma senha',
  },
  'journal_password_repeat': {
    'ru': 'Повторите пароль', 'en': 'Repeat the password',
    'de': 'Passwort wiederholen', 'fr': 'Répétez le mot de passe',
    'es': 'Repita la contraseña', 'it': 'Ripeti la password',
    'pt': 'Repita a senha',
  },
  'journal_password_enter': {
    'ru': 'Введите пароль', 'en': 'Enter the password',
    'de': 'Passwort eingeben', 'fr': 'Saisissez le mot de passe',
    'es': 'Escriba la contraseña', 'it': 'Inserisci la password',
    'pt': 'Digite a senha',
  },
  'journal_password_sub': {
    'ru': 'Спросим при входе в этот дневник. Код приложения останется прежним.',
    'en': 'We’ll ask for it when you open this journal. The app code stays as '
        'it is.',
    'de': 'Wir fragen danach beim Öffnen dieses Tagebuchs. Der App-Code bleibt '
        'unverändert.',
    'fr': 'Il sera demandé à l’ouverture de ce journal. Le code de '
        'l’application ne change pas.',
    'es': 'Se pedirá al abrir este diario. El código de la aplicación no '
        'cambia.',
    'it': 'Verrà chiesta all’apertura di questo diario. Il codice dell’app '
        'resta lo stesso.',
    'pt': 'Vamos pedi-la ao abrir este diário. O código do app continua o '
        'mesmo.',
  },
  'journal_password_short': {
    'ru': 'Не короче {n} символов', 'en': 'At least {n} characters',
    'de': 'Mindestens {n} Zeichen', 'fr': 'Au moins {n} caractères',
    'es': 'Al menos {n} caracteres', 'it': 'Almeno {n} caratteri',
    'pt': 'Pelo menos {n} caracteres',
  },
  'journal_password_mismatch': {
    'ru': 'Пароли не совпадают', 'en': 'The passwords don’t match',
    'de': 'Die Passwörter stimmen nicht überein',
    'fr': 'Les mots de passe ne correspondent pas',
    'es': 'Las contraseñas no coinciden', 'it': 'Le password non coincidono',
    'pt': 'As senhas não coincidem',
  },
  'journal_password_wrong': {
    'ru': 'Неверный пароль', 'en': 'Wrong password', 'de': 'Falsches Passwort',
    'fr': 'Mot de passe incorrect', 'es': 'Contraseña incorrecta',
    'it': 'Password errata', 'pt': 'Senha incorreta',
  },
  'journal_password_change': {
    'ru': 'Сменить пароль', 'en': 'Change password', 'de': 'Passwort ändern',
    'fr': 'Changer le mot de passe', 'es': 'Cambiar la contraseña',
    'it': 'Cambia password', 'pt': 'Alterar a senha',
  },
  'journal_forgot': {
    'ru': 'Забыли пароль?', 'en': 'Forgot the password?',
    'de': 'Passwort vergessen?', 'fr': 'Mot de passe oublié ?',
    'es': '¿Olvidó la contraseña?', 'it': 'Password dimenticata?',
    'pt': 'Esqueceu a senha?',
  },
  'journal_reset_msg': {
    'ru': 'Снять пароль с дневника? Записи останутся на месте, новый пароль '
        'задаётся в его настройках.',
    'en': 'Remove the journal password? The entries stay; set a new password '
        'in the journal’s settings.',
    'de': 'Passwort des Tagebuchs entfernen? Die Einträge bleiben; ein neues '
        'Passwort legst du in seinen Einstellungen an.',
    'fr': 'Retirer le mot de passe du journal ? Les entrées restent ; le '
        'nouveau mot de passe se définit dans ses réglages.',
    'es': '¿Quitar la contraseña del diario? Las anotaciones quedan; la nueva '
        'contraseña se pone en sus ajustes.',
    'it': 'Togliere la password del diario? Le voci restano; la nuova password '
        'si imposta nelle sue impostazioni.',
    'pt': 'Remover a senha do diário? As anotações ficam; a nova senha é '
        'definida nos ajustes dele.',
  },
  'journal_unlock': {
    'ru': 'Открыть', 'en': 'Unlock', 'de': 'Öffnen', 'fr': 'Ouvrir',
    'es': 'Abrir', 'it': 'Apri', 'pt': 'Abrir',
  },
  'journal_password_missing': {
    'ru': 'У этого дневника ещё нет своего пароля — придумайте его сейчас',
    'en': 'This journal has no password of its own yet — create one now',
    'de': 'Dieses Tagebuch hat noch kein eigenes Passwort — jetzt anlegen',
    'fr': 'Ce journal n’a pas encore son mot de passe — créez-le maintenant',
    'es': 'Este diario aún no tiene su contraseña: créela ahora',
    'it': 'Questo diario non ha ancora una password propria: creala ora',
    'pt': 'Este diário ainda não tem senha própria — crie uma agora',
  },
  'search_hint': {
    'ru': 'Искать по дневнику', 'en': 'Search your journal',
    'de': 'Im Tagebuch suchen', 'fr': 'Chercher dans le journal',
    'es': 'Buscar en el diario', 'it': 'Cerca nel diario',
    'pt': 'Buscar no diário',
  },
  'search_start_title': {
    'ru': 'Что вспоминаем?', 'en': 'What are we looking for?',
    'de': 'Woran erinnern wir uns?', 'fr': 'Qu’est-ce qu’on cherche ?',
    'es': '¿Qué recordamos?', 'it': 'Cosa cerchiamo?',
    'pt': 'O que vamos lembrar?',
  },
  'search_start_sub': {
    'ru': 'Слово из записи, место или надпись с фотографии',
    'en': 'A word from an entry, a place, or text on a photo',
    'de': 'Ein Wort aus einem Eintrag, ein Ort oder Text auf einem Foto',
    'fr': 'Un mot d’une entrée, un lieu ou du texte sur une photo',
    'es': 'Una palabra de una entrada, un lugar o texto en una foto',
    'it': 'Una parola da una voce, un luogo o testo su una foto',
    'pt': 'Uma palavra de uma anotação, um lugar ou texto numa foto',
  },
  'search_nothing_title': {
    'ru': 'Ничего не нашлось', 'en': 'Nothing found', 'de': 'Nichts gefunden',
    'fr': 'Rien trouvé', 'es': 'No se encontró nada', 'it': 'Niente trovato',
    'pt': 'Nada encontrado',
  },
  'search_nothing_sub': {
    'ru': 'Попробуй другое слово или сними фильтр',
    'en': 'Try another word or drop a filter',
    'de': 'Versuch ein anderes Wort oder nimm einen Filter weg',
    'fr': 'Essaie un autre mot ou enlève un filtre',
    'es': 'Prueba otra palabra o quita un filtro',
    'it': 'Prova un’altra parola o togli un filtro',
    'pt': 'Tente outra palavra ou tire um filtro',
  },
  'search_section_entries': {
    'ru': 'Записи', 'en': 'Entries', 'de': 'Einträge', 'fr': 'Entrées',
    'es': 'Entradas', 'it': 'Voci', 'pt': 'Anotações',
  },
  'search_section_photos': {
    'ru': 'На фото · OCR', 'en': 'On photos · OCR', 'de': 'Auf Fotos · OCR',
    'fr': 'Sur photos · OCR', 'es': 'En fotos · OCR', 'it': 'Su foto · OCR',
    'pt': 'Em fotos · OCR',
  },
  'found_on_photo': {
    'ru': 'распознано на фото', 'en': 'recognised on a photo',
    'de': 'auf einem Foto erkannt', 'fr': 'reconnu sur une photo',
    'es': 'reconocido en una foto', 'it': 'riconosciuto su una foto',
    'pt': 'reconhecido numa foto',
  },
  'corr_tracker_more': {
    'ru': '{name} побольше', 'en': 'More {name}', 'de': 'Mehr {name}',
    'fr': 'Plus de {name}', 'es': 'Más {name}', 'it': 'Più {name}',
    'pt': 'Mais {name}',
  },
  'corr_tracker_less': {
    'ru': '{name} поменьше', 'en': 'Less {name}', 'de': 'Weniger {name}',
    'fr': 'Moins de {name}', 'es': 'Menos {name}', 'it': 'Meno {name}',
    'pt': 'Menos {name}',
  },
  'entries_short': {
    'ru': 'записей', 'en': 'entries', 'de': 'Einträge', 'fr': 'entrées',
    'es': 'entradas', 'it': 'voci', 'pt': 'notas',
  },
  'words_short': {
    'ru': 'слов', 'en': 'words', 'de': 'Wörter', 'fr': 'mots',
    'es': 'palabras', 'it': 'parole', 'pt': 'palavras',
  },
  'days_written_short': {
    'ru': 'дней с записью', 'en': 'days written', 'de': 'Tage geschrieben',
    'fr': 'jours écrits', 'es': 'días escritos', 'it': 'giorni scritti',
    'pt': 'dias escritos',
  },
  'thousand_suffix': {
    'ru': 'к', 'en': 'k', 'de': 'Tsd', 'fr': 'k', 'es': 'mil', 'it': 'k',
    'pt': 'mil',
  },
  'day_empty': {
    'ru': 'В этот день записей нет', 'en': 'Nothing written on this day',
    'de': 'An diesem Tag gibt es nichts', 'fr': 'Rien d’écrit ce jour-là',
    'es': 'Nada escrito ese día', 'it': 'Niente scritto in questo giorno',
    'pt': 'Nada escrito nesse dia',
  },
  'day_write': {
    'ru': 'Записать этим днём', 'en': 'Write for this day',
    'de': 'Für diesen Tag schreiben', 'fr': 'Écrire pour ce jour',
    'es': 'Escribir para ese día', 'it': 'Scrivi per questo giorno',
    'pt': 'Escrever nesse dia',
  },
  'filter_favorite': {
    'ru': 'Избранное', 'en': 'Favorites', 'de': 'Favoriten', 'fr': 'Favoris',
    'es': 'Favoritos', 'it': 'Preferiti', 'pt': 'Favoritos',
  },
  'filter_with_photo': {
    'ru': 'С фото', 'en': 'With photo', 'de': 'Mit Foto', 'fr': 'Avec photo',
    'es': 'Con foto', 'it': 'Con foto', 'pt': 'Com foto',
  },
  'memories_empty_title': {
    'ru': 'В этот день пока пусто',
    'en': 'Nothing on this day yet',
    'de': 'An diesem Tag noch nichts',
    'fr': 'Rien pour ce jour',
    'es': 'Aún nada en este día',
    'it': 'Ancora niente in questo giorno',
    'pt': 'Ainda nada neste dia',
  },
  'memories_empty_sub': {
    'ru': 'Через год эта дата будет с записями',
    'en': 'In a year this date will have entries',
    'de': 'In einem Jahr hat dieses Datum Einträge',
    'fr': 'Dans un an, cette date aura des entrées',
    'es': 'En un año esta fecha tendrá entradas',
    'it': 'Tra un anno questa data avrà delle voci',
    'pt': 'Em um ano esta data terá anotações',
  },
};
