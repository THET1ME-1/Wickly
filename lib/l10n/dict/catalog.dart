/// Раздел И макета: свои эмоции и действия, трекеры и привычки.
///
/// Здесь же имена **встроенных** элементов каталога: в базе у них лежит только
/// ключ, поэтому нетронутая «радость» переезжает вместе с языком интерфейса.
///
/// Одна запись = семь языков (ru · en · de · fr · es · it · pt).
library;

const Map<String, Map<String, String>> catalogStrings = {
  // --------------------------- Общие подписи ---------------------------
  'own': {
    'ru': 'своё', 'en': 'own', 'de': 'eigenes', 'fr': 'perso',
    'es': 'propio', 'it': 'proprio', 'pt': 'próprio',
  },
  'mood_behind': {
    'ru': 'Что за этим стоит', 'en': 'What is behind it',
    'de': 'Was dahintersteckt', 'fr': 'Ce qu’il y a derrière',
    'es': 'Qué hay detrás', 'it': 'Che cosa c’è dietro',
    'pt': 'O que está por trás',
  },
  'mood_did': {
    'ru': 'Что делал', 'en': 'What you did', 'de': 'Was du gemacht hast',
    'fr': 'Ce que tu as fait', 'es': 'Qué hiciste', 'it': 'Cosa hai fatto',
    'pt': 'O que você fez',
  },
  'emotions_and_activities': {
    'ru': 'Эмоции и действия', 'en': 'Emotions and activities',
    'de': 'Gefühle und Aktivitäten', 'fr': 'Émotions et activités',
    'es': 'Emociones y actividades', 'it': 'Emozioni e attività',
    'pt': 'Emoções e atividades',
  },
  'tab_emotions': {
    'ru': 'Эмоции', 'en': 'Emotions', 'de': 'Gefühle', 'fr': 'Émotions',
    'es': 'Emociones', 'it': 'Emozioni', 'pt': 'Emoções',
  },
  'tab_activities': {
    'ru': 'Действия', 'en': 'Activities', 'de': 'Aktivitäten',
    'fr': 'Activités', 'es': 'Actividades', 'it': 'Attività',
    'pt': 'Atividades',
  },
  'drag_to_order': {
    'ru': 'удерживай и перетаскивай, чтобы упорядочить',
    'en': 'hold and drag to reorder',
    'de': 'halten und ziehen zum Sortieren',
    'fr': 'maintiens et fais glisser pour réordonner',
    'es': 'mantén y arrastra para ordenar',
    'it': 'tieni premuto e trascina per ordinare',
    'pt': 'segure e arraste para reordenar',
  },
  'pleasant': {
    'ru': 'Приятные', 'en': 'Pleasant', 'de': 'Angenehme', 'fr': 'Agréables',
    'es': 'Agradables', 'it': 'Piacevoli', 'pt': 'Agradáveis',
  },
  'hard': {
    'ru': 'Тяжёлые', 'en': 'Hard', 'de': 'Schwere', 'fr': 'Difficiles',
    'es': 'Difíciles', 'it': 'Pesanti', 'pt': 'Difíceis',
  },
  'create_emotion': {
    'ru': 'Создать эмоцию', 'en': 'Create an emotion', 'de': 'Gefühl anlegen',
    'fr': 'Créer une émotion', 'es': 'Crear una emoción',
    'it': 'Crea un’emozione', 'pt': 'Criar uma emoção',
  },
  'create_activity': {
    'ru': 'Создать действие', 'en': 'Create an activity',
    'de': 'Aktivität anlegen', 'fr': 'Créer une activité',
    'es': 'Crear una actividad', 'it': 'Crea un’attività',
    'pt': 'Criar uma atividade',
  },
  'new_emotion': {
    'ru': 'Новая эмоция', 'en': 'New emotion', 'de': 'Neues Gefühl',
    'fr': 'Nouvelle émotion', 'es': 'Nueva emoción', 'it': 'Nuova emozione',
    'pt': 'Nova emoção',
  },
  'new_activity': {
    'ru': 'Новое действие', 'en': 'New activity', 'de': 'Neue Aktivität',
    'fr': 'Nouvelle activité', 'es': 'Nueva actividad', 'it': 'Nuova attività',
    'pt': 'Nova atividade',
  },
  'name': {
    'ru': 'Название', 'en': 'Name', 'de': 'Name', 'fr': 'Nom',
    'es': 'Nombre', 'it': 'Nome', 'pt': 'Nome',
  },
  'icon': {
    'ru': 'Иконка', 'en': 'Icon', 'de': 'Symbol', 'fr': 'Icône',
    'es': 'Icono', 'it': 'Icona', 'pt': 'Ícone',
  },
  'color': {
    'ru': 'Цвет', 'en': 'Color', 'de': 'Farbe', 'fr': 'Couleur',
    'es': 'Color', 'it': 'Colore', 'pt': 'Cor',
  },
  'category': {
    'ru': 'Категория', 'en': 'Category', 'de': 'Kategorie', 'fr': 'Catégorie',
    'es': 'Categoría', 'it': 'Categoria', 'pt': 'Categoria',
  },
  'delete_from_catalog_q': {
    'ru': 'Убрать «{name}» из каталога? Отметки в прошлых записях пропадут.',
    'en': 'Remove “{name}” from the catalog? Marks in past entries will go.',
    'de': '„{name}“ aus dem Katalog entfernen? Markierungen in früheren '
        'Einträgen verschwinden.',
    'fr': 'Retirer « {name} » du catalogue ? Les marques des entrées passées '
        'disparaîtront.',
    'es': '¿Quitar «{name}» del catálogo? Las marcas de entradas pasadas '
        'desaparecerán.',
    'it': 'Togliere «{name}» dal catalogo? I segni nelle voci passate '
        'spariranno.',
    'pt': 'Remover “{name}” do catálogo? As marcas em anotações antigas '
        'sumirão.',
  },

  // --------------------- Категории действий ---------------------
  'cat_people': {
    'ru': 'Люди', 'en': 'People', 'de': 'Menschen', 'fr': 'Gens',
    'es': 'Gente', 'it': 'Persone', 'pt': 'Pessoas',
  },
  'cat_body': {
    'ru': 'Тело', 'en': 'Body', 'de': 'Körper', 'fr': 'Corps',
    'es': 'Cuerpo', 'it': 'Corpo', 'pt': 'Corpo',
  },
  'cat_home': {
    'ru': 'Дом и дела', 'en': 'Home and chores', 'de': 'Zuhause und Aufgaben',
    'fr': 'Maison et tâches', 'es': 'Casa y tareas', 'it': 'Casa e faccende',
    'pt': 'Casa e tarefas',
  },
  'cat_rest': {
    'ru': 'Отдых', 'en': 'Rest', 'de': 'Erholung', 'fr': 'Détente',
    'es': 'Descanso', 'it': 'Riposo', 'pt': 'Descanso',
  },

  // ---------------------- Встроенные эмоции ----------------------
  'emo_calm': {
    'ru': 'спокойствие', 'en': 'calm', 'de': 'Ruhe', 'fr': 'calme',
    'es': 'calma', 'it': 'calma', 'pt': 'calma',
  },
  'emo_joy': {
    'ru': 'радость', 'en': 'joy', 'de': 'Freude', 'fr': 'joie',
    'es': 'alegría', 'it': 'gioia', 'pt': 'alegria',
  },
  'emo_gratitude': {
    'ru': 'благодарность', 'en': 'gratitude', 'de': 'Dankbarkeit',
    'fr': 'gratitude', 'es': 'gratitud', 'it': 'gratitudine',
    'pt': 'gratidão',
  },
  'emo_inspiration': {
    'ru': 'вдохновение', 'en': 'inspiration', 'de': 'Inspiration',
    'fr': 'inspiration', 'es': 'inspiración', 'it': 'ispirazione',
    'pt': 'inspiração',
  },
  'emo_love': {
    'ru': 'нежность', 'en': 'love', 'de': 'Zuneigung', 'fr': 'tendresse',
    'es': 'cariño', 'it': 'tenerezza', 'pt': 'carinho',
  },
  'emo_tired': {
    'ru': 'усталость', 'en': 'tiredness', 'de': 'Müdigkeit', 'fr': 'fatigue',
    'es': 'cansancio', 'it': 'stanchezza', 'pt': 'cansaço',
  },
  'emo_anxiety': {
    'ru': 'тревога', 'en': 'anxiety', 'de': 'Unruhe', 'fr': 'anxiété',
    'es': 'ansiedad', 'it': 'ansia', 'pt': 'ansiedade',
  },
  'emo_sad': {
    'ru': 'грусть', 'en': 'sadness', 'de': 'Traurigkeit', 'fr': 'tristesse',
    'es': 'tristeza', 'it': 'tristezza', 'pt': 'tristeza',
  },
  'emo_angry': {
    'ru': 'злость', 'en': 'anger', 'de': 'Ärger', 'fr': 'colère',
    'es': 'enfado', 'it': 'rabbia', 'pt': 'raiva',
  },

  // --------------------- Встроенные действия ---------------------
  'act_friends': {
    'ru': 'друзья', 'en': 'friends', 'de': 'Freunde', 'fr': 'amis',
    'es': 'amigos', 'it': 'amici', 'pt': 'amigos',
  },
  'act_family': {
    'ru': 'семья', 'en': 'family', 'de': 'Familie', 'fr': 'famille',
    'es': 'familia', 'it': 'famiglia', 'pt': 'família',
  },
  'act_date': {
    'ru': 'свидание', 'en': 'date', 'de': 'Date', 'fr': 'rendez-vous',
    'es': 'cita', 'it': 'appuntamento', 'pt': 'encontro',
  },
  'act_sport': {
    'ru': 'спорт', 'en': 'sport', 'de': 'Sport', 'fr': 'sport',
    'es': 'deporte', 'it': 'sport', 'pt': 'esporte',
  },
  'act_walk': {
    'ru': 'прогулка', 'en': 'a walk', 'de': 'Spaziergang', 'fr': 'balade',
    'es': 'paseo', 'it': 'passeggiata', 'pt': 'caminhada',
  },
  'act_sleep': {
    'ru': 'сон', 'en': 'sleep', 'de': 'Schlaf', 'fr': 'sommeil',
    'es': 'sueño', 'it': 'sonno', 'pt': 'sono',
  },
  'act_cooking': {
    'ru': 'готовка', 'en': 'cooking', 'de': 'Kochen', 'fr': 'cuisine',
    'es': 'cocinar', 'it': 'cucinare', 'pt': 'cozinhar',
  },
  'act_work': {
    'ru': 'работа', 'en': 'work', 'de': 'Arbeit', 'fr': 'travail',
    'es': 'trabajo', 'it': 'lavoro', 'pt': 'trabalho',
  },
  'act_shopping': {
    'ru': 'покупки', 'en': 'shopping', 'de': 'Einkaufen', 'fr': 'courses',
    'es': 'compras', 'it': 'spesa', 'pt': 'compras',
  },
  'act_coffee': {
    'ru': 'кофе', 'en': 'coffee', 'de': 'Kaffee', 'fr': 'café',
    'es': 'café', 'it': 'caffè', 'pt': 'café',
  },
  'act_movie': {
    'ru': 'кино', 'en': 'a film', 'de': 'Kino', 'fr': 'ciné',
    'es': 'cine', 'it': 'film', 'pt': 'cinema',
  },
  'act_book': {
    'ru': 'книга', 'en': 'a book', 'de': 'Buch', 'fr': 'livre',
    'es': 'libro', 'it': 'libro', 'pt': 'livro',
  },

  // --------------------- Трекеры и привычки ---------------------
  'trackers': {
    'ru': 'Трекеры', 'en': 'Trackers', 'de': 'Tracker', 'fr': 'Suivis',
    'es': 'Seguimientos', 'it': 'Tracker', 'pt': 'Rastreadores',
  },
  'habits': {
    'ru': 'Привычки', 'en': 'Habits', 'de': 'Gewohnheiten', 'fr': 'Habitudes',
    'es': 'Hábitos', 'it': 'Abitudini', 'pt': 'Hábitos',
  },
  'new_tracker': {
    'ru': 'Новый трекер', 'en': 'New tracker', 'de': 'Neuer Tracker',
    'fr': 'Nouveau suivi', 'es': 'Nuevo seguimiento', 'it': 'Nuovo tracker',
    'pt': 'Novo rastreador',
  },
  'tracker_goal': {
    'ru': 'Цель на день', 'en': 'Daily goal', 'de': 'Tagesziel',
    'fr': 'Objectif du jour', 'es': 'Meta diaria', 'it': 'Obiettivo del giorno',
    'pt': 'Meta do dia',
  },
  'tracker_kind': {
    'ru': 'Что считаем', 'en': 'What to count', 'de': 'Was zählen wir',
    'fr': 'Que compter', 'es': 'Qué contamos', 'it': 'Cosa contiamo',
    'pt': 'O que contar',
  },
  'kind_number': {
    'ru': 'Число', 'en': 'Number', 'de': 'Zahl', 'fr': 'Nombre',
    'es': 'Número', 'it': 'Numero', 'pt': 'Número',
  },
  'kind_duration': {
    'ru': 'Часы', 'en': 'Hours', 'de': 'Stunden', 'fr': 'Heures',
    'es': 'Horas', 'it': 'Ore', 'pt': 'Horas',
  },
  'kind_habit': {
    'ru': 'Привычка', 'en': 'Habit', 'de': 'Gewohnheit', 'fr': 'Habitude',
    'es': 'Hábito', 'it': 'Abitudine', 'pt': 'Hábito',
  },
  'trk_water': {
    'ru': 'вода', 'en': 'water', 'de': 'Wasser', 'fr': 'eau',
    'es': 'agua', 'it': 'acqua', 'pt': 'água',
  },
  'trk_sleep': {
    'ru': 'сон', 'en': 'sleep', 'de': 'Schlaf', 'fr': 'sommeil',
    'es': 'sueño', 'it': 'sonno', 'pt': 'sono',
  },
  'trk_steps': {
    'ru': 'шаги', 'en': 'steps', 'de': 'Schritte', 'fr': 'pas',
    'es': 'pasos', 'it': 'passi', 'pt': 'passos',
  },
  'trk_read': {
    'ru': 'Читать', 'en': 'Read', 'de': 'Lesen', 'fr': 'Lire',
    'es': 'Leer', 'it': 'Leggere', 'pt': 'Ler',
  },
  'trk_workout': {
    'ru': 'Зарядка', 'en': 'Workout', 'de': 'Sport', 'fr': 'Exercice',
    'es': 'Ejercicio', 'it': 'Allenamento', 'pt': 'Exercício',
  },
  'trk_no_social': {
    'ru': 'Без соцсетей', 'en': 'No social media', 'de': 'Ohne Social Media',
    'fr': 'Sans réseaux', 'es': 'Sin redes', 'it': 'Senza social',
    'pt': 'Sem redes sociais',
  },
  'unit_glasses': {
    'ru': 'стак.', 'en': 'glasses', 'de': 'Gläser', 'fr': 'verres',
    'es': 'vasos', 'it': 'bicchieri', 'pt': 'copos',
  },
  'unit_hours': {
    'ru': 'ч', 'en': 'h', 'de': 'Std.', 'fr': 'h', 'es': 'h', 'it': 'h',
    'pt': 'h',
  },
  'unit_steps': {
    'ru': 'шагов', 'en': 'steps', 'de': 'Schritte', 'fr': 'pas',
    'es': 'pasos', 'it': 'passi', 'pt': 'passos',
  },
};
