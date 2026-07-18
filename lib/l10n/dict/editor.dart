/// Раздел В макета: редактор, голос и диктовка, читалка записи.
///
/// Одна запись = семь языков (ru · en · de · fr · es · it · pt).
library;

const Map<String, Map<String, String>> editorStrings = {
  // ----------------------------- Редактор -----------------------------
  'draft_saved': {
    'ru': 'Черновик · автосохранён', 'en': 'Draft · saved',
    'de': 'Entwurf · gespeichert', 'fr': 'Brouillon · enregistré',
    'es': 'Borrador · guardado', 'it': 'Bozza · salvata',
    'pt': 'Rascunho · salvo',
  },
  'entry_title_hint': {
    'ru': 'Заголовок', 'en': 'Title', 'de': 'Titel', 'fr': 'Titre',
    'es': 'Título', 'it': 'Titolo', 'pt': 'Título',
  },
  'entry_body_hint': {
    'ru': 'Как прошёл день?', 'en': 'How was your day?',
    'de': 'Wie war dein Tag?', 'fr': 'Comment s’est passée ta journée ?',
    'es': '¿Cómo fue tu día?', 'it': 'Com’è andata la giornata?',
    'pt': 'Como foi o seu dia?',
  },
  'add_photo': {
    'ru': 'Фото', 'en': 'Photo', 'de': 'Foto', 'fr': 'Photo',
    'es': 'Foto', 'it': 'Foto', 'pt': 'Foto',
  },
  'take_photo': {
    'ru': 'Камера', 'en': 'Camera', 'de': 'Kamera', 'fr': 'Appareil photo',
    'es': 'Cámara', 'it': 'Fotocamera', 'pt': 'Câmera',
  },
  'add_video': {
    'ru': 'Видео', 'en': 'Video', 'de': 'Video', 'fr': 'Vidéo',
    'es': 'Vídeo', 'it': 'Video', 'pt': 'Vídeo',
  },
  'add_file': {
    'ru': 'Файл', 'en': 'File', 'de': 'Datei', 'fr': 'Fichier',
    'es': 'Archivo', 'it': 'File', 'pt': 'Arquivo',
  },
  'add_sketch': {
    'ru': 'Рисунок', 'en': 'Sketch', 'de': 'Zeichnung', 'fr': 'Croquis',
    'es': 'Dibujo', 'it': 'Schizzo', 'pt': 'Desenho',
  },
  'voice': {
    'ru': 'Голос', 'en': 'Voice', 'de': 'Stimme', 'fr': 'Voix',
    'es': 'Voz', 'it': 'Voce', 'pt': 'Voz',
  },
  'set_place': {
    'ru': 'Место', 'en': 'Place', 'de': 'Ort', 'fr': 'Lieu',
    'es': 'Lugar', 'it': 'Luogo', 'pt': 'Lugar',
  },
  'set_mood': {
    'ru': 'Настроение', 'en': 'Mood', 'de': 'Stimmung', 'fr': 'Humeur',
    'es': 'Ánimo', 'it': 'Umore', 'pt': 'Humor',
  },
  'add_tag': {
    'ru': 'Тег', 'en': 'Tag', 'de': 'Tag', 'fr': 'Étiquette',
    'es': 'Etiqueta', 'it': 'Tag', 'pt': 'Marcador',
  },
  'format_bold': {
    'ru': 'Жирный', 'en': 'Bold', 'de': 'Fett', 'fr': 'Gras',
    'es': 'Negrita', 'it': 'Grassetto', 'pt': 'Negrito',
  },
  'format_italic': {
    'ru': 'Курсив', 'en': 'Italic', 'de': 'Kursiv', 'fr': 'Italique',
    'es': 'Cursiva', 'it': 'Corsivo', 'pt': 'Itálico',
  },
  'format_heading': {
    'ru': 'Заголовок', 'en': 'Heading', 'de': 'Überschrift', 'fr': 'Titre',
    'es': 'Encabezado', 'it': 'Titolo', 'pt': 'Título',
  },
  'format_list': {
    'ru': 'Список', 'en': 'List', 'de': 'Liste', 'fr': 'Liste',
    'es': 'Lista', 'it': 'Elenco', 'pt': 'Lista',
  },
  'format_todo': {
    'ru': 'Чеклист', 'en': 'Checklist', 'de': 'Checkliste',
    'fr': 'Liste de tâches', 'es': 'Lista de tareas', 'it': 'Lista di cose',
    'pt': 'Lista de tarefas',
  },
  'format_quote': {
    'ru': 'Цитата', 'en': 'Quote', 'de': 'Zitat', 'fr': 'Citation',
    'es': 'Cita', 'it': 'Citazione', 'pt': 'Citação',
  },
  'entry_deleted': {
    'ru': 'Запись удалена', 'en': 'Entry deleted', 'de': 'Eintrag gelöscht',
    'fr': 'Entrée supprimée', 'es': 'Entrada eliminada', 'it': 'Voce eliminata',
    'pt': 'Anotação excluída',
  },
  'undo': {
    'ru': 'Вернуть', 'en': 'Undo', 'de': 'Rückgängig', 'fr': 'Annuler',
    'es': 'Deshacer', 'it': 'Annulla', 'pt': 'Desfazer',
  },
  'discard_entry_q': {
    'ru': 'Удалить пустую запись?', 'en': 'Discard the empty entry?',
    'de': 'Leeren Eintrag verwerfen?', 'fr': 'Supprimer l’entrée vide ?',
    'es': '¿Descartar la entrada vacía?', 'it': 'Eliminare la voce vuota?',
    'pt': 'Descartar a anotação vazia?',
  },

  // ------------------------- Голос и диктовка -------------------------
  'voice_dictation': {
    'ru': 'Диктовка → текст', 'en': 'Dictation → text',
    'de': 'Diktat → Text', 'fr': 'Dictée → texte',
    'es': 'Dictado → texto', 'it': 'Dettatura → testo',
    'pt': 'Ditado → texto',
  },
  'voice_note': {
    'ru': 'Аудио-заметка', 'en': 'Audio note', 'de': 'Sprachnotiz',
    'fr': 'Note audio', 'es': 'Nota de audio', 'it': 'Nota audio',
    'pt': 'Nota de áudio',
  },
  'voice_transcript': {
    'ru': 'Расшифровка', 'en': 'Transcript', 'de': 'Transkript',
    'fr': 'Transcription', 'es': 'Transcripción', 'it': 'Trascrizione',
    'pt': 'Transcrição',
  },
  'voice_listening': {
    'ru': 'Слушаю…', 'en': 'Listening…', 'de': 'Höre zu…',
    'fr': 'J’écoute…', 'es': 'Escuchando…', 'it': 'Ascolto…',
    'pt': 'Ouvindo…',
  },
  'voice_tap_to_start': {
    'ru': 'Нажми и говори', 'en': 'Tap and speak', 'de': 'Tippen und sprechen',
    'fr': 'Appuie et parle', 'es': 'Toca y habla', 'it': 'Tocca e parla',
    'pt': 'Toque e fale',
  },
  'voice_unavailable': {
    'ru': 'Распознавание речи недоступно на этом телефоне',
    'en': 'Speech recognition is unavailable on this phone',
    'de': 'Spracherkennung ist auf diesem Handy nicht verfügbar',
    'fr': 'La reconnaissance vocale n’est pas disponible sur ce téléphone',
    'es': 'El reconocimiento de voz no está disponible en este teléfono',
    'it': 'Il riconoscimento vocale non è disponibile su questo telefono',
    'pt': 'O reconhecimento de fala não está disponível neste telefone',
  },
  'mic_denied': {
    'ru': 'Нужен доступ к микрофону',
    'en': 'Microphone access is needed',
    'de': 'Zugriff aufs Mikrofon nötig',
    'fr': 'L’accès au micro est nécessaire',
    'es': 'Se necesita acceso al micrófono',
    'it': 'Serve l’accesso al microfono',
    'pt': 'É preciso acesso ao microfone',
  },

  // ------------------------------ Читалка ------------------------------
  'in_favorites': {
    'ru': 'В избранном', 'en': 'In favorites', 'de': 'In Favoriten',
    'fr': 'Dans les favoris', 'es': 'En favoritos', 'it': 'Nei preferiti',
    'pt': 'Nos favoritos',
  },
  'add_to_favorites': {
    'ru': 'В избранное', 'en': 'Add to favorites', 'de': 'Zu Favoriten',
    'fr': 'Ajouter aux favoris', 'es': 'Añadir a favoritos',
    'it': 'Aggiungi ai preferiti', 'pt': 'Adicionar aos favoritos',
  },
  'pin_entry': {
    'ru': 'Закрепить', 'en': 'Pin', 'de': 'Anheften', 'fr': 'Épingler',
    'es': 'Fijar', 'it': 'Fissa', 'pt': 'Fixar',
  },
  'unpin_entry': {
    'ru': 'Открепить', 'en': 'Unpin', 'de': 'Lösen', 'fr': 'Détacher',
    'es': 'Desfijar', 'it': 'Sblocca', 'pt': 'Desafixar',
  },
  'hide_entry': {
    'ru': 'Скрыть запись', 'en': 'Hide entry', 'de': 'Eintrag verbergen',
    'fr': 'Masquer l’entrée', 'es': 'Ocultar entrada', 'it': 'Nascondi voce',
    'pt': 'Ocultar anotação',
  },
  'unhide_entry': {
    'ru': 'Показывать снова', 'en': 'Show again', 'de': 'Wieder zeigen',
    'fr': 'Réafficher', 'es': 'Mostrar de nuevo', 'it': 'Mostra di nuovo',
    'pt': 'Mostrar de novo',
  },
  'share_entry': {
    'ru': 'Поделиться', 'en': 'Share', 'de': 'Teilen', 'fr': 'Partager',
    'es': 'Compartir', 'it': 'Condividi', 'pt': 'Compartilhar',
  },
  'move_to_journal': {
    'ru': 'Перенести в дневник', 'en': 'Move to journal',
    'de': 'In Tagebuch verschieben', 'fr': 'Déplacer vers un journal',
    'es': 'Mover a un diario', 'it': 'Sposta in un diario',
    'pt': 'Mover para um diário',
  },

  // ------------------------------ Погода ------------------------------
  'weather_clear': {
    'ru': 'ясно', 'en': 'clear', 'de': 'klar', 'fr': 'dégagé',
    'es': 'despejado', 'it': 'sereno', 'pt': 'limpo',
  },
  'weather_partly': {
    'ru': 'малооблачно', 'en': 'partly cloudy', 'de': 'leicht bewölkt',
    'fr': 'peu nuageux', 'es': 'poco nuboso', 'it': 'poco nuvoloso',
    'pt': 'parcialmente nublado',
  },
  'weather_cloudy': {
    'ru': 'облачно', 'en': 'cloudy', 'de': 'bewölkt', 'fr': 'nuageux',
    'es': 'nublado', 'it': 'nuvoloso', 'pt': 'nublado',
  },
  'weather_fog': {
    'ru': 'туман', 'en': 'fog', 'de': 'Nebel', 'fr': 'brouillard',
    'es': 'niebla', 'it': 'nebbia', 'pt': 'névoa',
  },
  'weather_drizzle': {
    'ru': 'морось', 'en': 'drizzle', 'de': 'Nieselregen', 'fr': 'bruine',
    'es': 'llovizna', 'it': 'pioggerella', 'pt': 'garoa',
  },
  'weather_rain': {
    'ru': 'дождь', 'en': 'rain', 'de': 'Regen', 'fr': 'pluie',
    'es': 'lluvia', 'it': 'pioggia', 'pt': 'chuva',
  },
  'weather_snow': {
    'ru': 'снег', 'en': 'snow', 'de': 'Schnee', 'fr': 'neige',
    'es': 'nieve', 'it': 'neve', 'pt': 'neve',
  },
  'weather_storm': {
    'ru': 'гроза', 'en': 'storm', 'de': 'Gewitter', 'fr': 'orage',
    'es': 'tormenta', 'it': 'temporale', 'pt': 'tempestade',
  },
};
