/// Журнальные подсказки: пять наборов по пять вопросов.
///
/// Вопросы намеренно конкретные: «за что ты благодарен» человек пропускает,
/// а «кто сегодня облегчил тебе день» — вспоминает.
///
/// Одна запись = семь языков (ru · en · de · fr · es · it · pt).
library;

const Map<String, Map<String, String>> promptStrings = {
  // ---------------------------- Названия наборов ----------------------------
  'pack_gratitude': {
    'ru': 'Благодарность', 'en': 'Gratitude', 'de': 'Dankbarkeit',
    'fr': 'Gratitude', 'es': 'Gratitud', 'it': 'Gratitudine',
    'pt': 'Gratidão',
  },
  'pack_reflection': {
    'ru': 'Рефлексия', 'en': 'Reflection', 'de': 'Reflexion',
    'fr': 'Réflexion', 'es': 'Reflexión', 'it': 'Riflessione',
    'pt': 'Reflexão',
  },
  'pack_goals': {
    'ru': 'Цели', 'en': 'Goals', 'de': 'Ziele', 'fr': 'Objectifs',
    'es': 'Metas', 'it': 'Obiettivi', 'pt': 'Metas',
  },
  'pack_relations': {
    'ru': 'Отношения', 'en': 'Relationships', 'de': 'Beziehungen',
    'fr': 'Relations', 'es': 'Relaciones', 'it': 'Relazioni',
    'pt': 'Relações',
  },
  'pack_creative': {
    'ru': 'Творчество', 'en': 'Creativity', 'de': 'Kreativität',
    'fr': 'Créativité', 'es': 'Creatividad', 'it': 'Creatività',
    'pt': 'Criatividade',
  },

  // ------------------------------ Благодарность ------------------------------
  'prompt_gratitude_1': {
    'ru': 'За что ты сегодня благодарен?',
    'en': 'What are you grateful for today?',
    'de': 'Wofür bist du heute dankbar?',
    'fr': 'De quoi es-tu reconnaissant aujourd’hui ?',
    'es': '¿Por qué estás agradecido hoy?',
    'it': 'Per cosa sei grato oggi?',
    'pt': 'Pelo que você é grato hoje?',
  },
  'prompt_gratitude_2': {
    'ru': 'Что получилось лучше, чем ты ждал?',
    'en': 'What went better than you expected?',
    'de': 'Was lief besser als erwartet?',
    'fr': 'Qu’est-ce qui s’est mieux passé que prévu ?',
    'es': '¿Qué salió mejor de lo que esperabas?',
    'it': 'Cosa è andato meglio del previsto?',
    'pt': 'O que saiu melhor do que você esperava?',
  },
  'prompt_gratitude_3': {
    'ru': 'Кто сегодня облегчил тебе день?',
    'en': 'Who made your day easier today?',
    'de': 'Wer hat dir den Tag heute leichter gemacht?',
    'fr': 'Qui t’a facilité la journée aujourd’hui ?',
    'es': '¿Quién te hizo el día más fácil hoy?',
    'it': 'Chi ti ha alleggerito la giornata oggi?',
    'pt': 'Quem tornou seu dia mais leve hoje?',
  },
  'prompt_gratitude_4': {
    'ru': 'Какая мелочь сегодня порадовала?',
    'en': 'What small thing made you happy today?',
    'de': 'Welche Kleinigkeit hat dich heute gefreut?',
    'fr': 'Quel petit rien t’a fait plaisir aujourd’hui ?',
    'es': '¿Qué pequeña cosa te alegró hoy?',
    'it': 'Quale piccolezza ti ha fatto piacere oggi?',
    'pt': 'Que coisinha te alegrou hoje?',
  },
  'prompt_gratitude_5': {
    'ru': 'Что из сегодняшнего хочется повторить?',
    'en': 'What from today would you do again?',
    'de': 'Was von heute würdest du wiederholen?',
    'fr': 'Que referais-tu de cette journée ?',
    'es': '¿Qué de hoy repetirías?',
    'it': 'Cosa di oggi rifaresti?',
    'pt': 'O que de hoje você repetiria?',
  },

  // -------------------------------- Рефлексия --------------------------------
  'prompt_reflection_1': {
    'ru': 'Что сегодня отняло больше всего сил?',
    'en': 'What took the most out of you today?',
    'de': 'Was hat dich heute am meisten gekostet?',
    'fr': 'Qu’est-ce qui t’a le plus épuisé aujourd’hui ?',
    'es': '¿Qué te quitó más energía hoy?',
    'it': 'Cosa ti ha tolto più energie oggi?',
    'pt': 'O que mais tomou sua energia hoje?',
  },
  'prompt_reflection_2': {
    'ru': 'О чём ты думал по дороге домой?',
    'en': 'What were you thinking about on the way home?',
    'de': 'Woran hast du auf dem Heimweg gedacht?',
    'fr': 'À quoi pensais-tu en rentrant ?',
    'es': '¿En qué pensabas de camino a casa?',
    'it': 'A cosa pensavi tornando a casa?',
    'pt': 'No que você pensou no caminho de casa?',
  },
  'prompt_reflection_3': {
    'ru': 'Что бы ты сделал иначе?',
    'en': 'What would you do differently?',
    'de': 'Was würdest du anders machen?',
    'fr': 'Que ferais-tu autrement ?',
    'es': '¿Qué harías diferente?',
    'it': 'Cosa faresti diversamente?',
    'pt': 'O que você faria diferente?',
  },
  'prompt_reflection_4': {
    'ru': 'Какое чувство сегодня возвращалось чаще всего?',
    'en': 'Which feeling kept coming back today?',
    'de': 'Welches Gefühl kam heute immer wieder?',
    'fr': 'Quel sentiment est revenu le plus souvent ?',
    'es': '¿Qué sentimiento volvió más veces hoy?',
    'it': 'Quale sensazione è tornata più spesso oggi?',
    'pt': 'Qual sentimento voltou mais vezes hoje?',
  },
  'prompt_reflection_5': {
    'ru': 'Чему сегодняшний день тебя научил?',
    'en': 'What did today teach you?',
    'de': 'Was hat dich der heutige Tag gelehrt?',
    'fr': 'Que t’a appris cette journée ?',
    'es': '¿Qué te enseñó el día de hoy?',
    'it': 'Cosa ti ha insegnato oggi?',
    'pt': 'O que o dia de hoje te ensinou?',
  },

  // ---------------------------------- Цели ----------------------------------
  'prompt_goals_1': {
    'ru': 'Что важное сдвинулось сегодня?',
    'en': 'What important thing moved today?',
    'de': 'Was Wichtiges hat sich heute bewegt?',
    'fr': 'Qu’est-ce qui a avancé aujourd’hui ?',
    'es': '¿Qué cosa importante avanzó hoy?',
    'it': 'Cosa di importante si è mosso oggi?',
    'pt': 'O que de importante avançou hoje?',
  },
  'prompt_goals_2': {
    'ru': 'Какой один шаг сделаешь завтра?',
    'en': 'What single step will you take tomorrow?',
    'de': 'Welchen einen Schritt machst du morgen?',
    'fr': 'Quel pas feras-tu demain ?',
    'es': '¿Qué paso darás mañana?',
    'it': 'Quale passo farai domani?',
    'pt': 'Que passo você dará amanhã?',
  },
  'prompt_goals_3': {
    'ru': 'Что мешает больше всего прямо сейчас?',
    'en': 'What is getting in the way most right now?',
    'de': 'Was stört gerade am meisten?',
    'fr': 'Qu’est-ce qui te bloque le plus maintenant ?',
    'es': '¿Qué te estorba más ahora mismo?',
    'it': 'Cosa ti ostacola di più adesso?',
    'pt': 'O que mais atrapalha agora?',
  },
  'prompt_goals_4': {
    'ru': 'Где ты сейчас относительно того, чего хотел?',
    'en': 'Where are you compared to what you wanted?',
    'de': 'Wo stehst du im Vergleich zu dem, was du wolltest?',
    'fr': 'Où en es-tu par rapport à ce que tu voulais ?',
    'es': '¿Dónde estás respecto a lo que querías?',
    'it': 'A che punto sei rispetto a ciò che volevi?',
    'pt': 'Onde você está em relação ao que queria?',
  },
  'prompt_goals_5': {
    'ru': 'От чего пора отказаться?',
    'en': 'What is it time to let go of?',
    'de': 'Wovon solltest du dich trennen?',
    'fr': 'De quoi est-il temps de te séparer ?',
    'es': '¿De qué toca desprenderse?',
    'it': 'A cosa è ora di rinunciare?',
    'pt': 'Do que já é hora de abrir mão?',
  },

  // -------------------------------- Отношения --------------------------------
  'prompt_relations_1': {
    'ru': 'С кем ты сегодня говорил дольше всего?',
    'en': 'Who did you talk to the longest today?',
    'de': 'Mit wem hast du heute am längsten geredet?',
    'fr': 'Avec qui as-tu le plus parlé aujourd’hui ?',
    'es': '¿Con quién hablaste más tiempo hoy?',
    'it': 'Con chi hai parlato di più oggi?',
    'pt': 'Com quem você mais conversou hoje?',
  },
  'prompt_relations_2': {
    'ru': 'Кому ты давно не писал?',
    'en': 'Who have you not written to in a while?',
    'de': 'Wem hast du lange nicht geschrieben?',
    'fr': 'À qui n’as-tu pas écrit depuis longtemps ?',
    'es': '¿A quién hace tiempo que no escribes?',
    'it': 'A chi non scrivi da tempo?',
    'pt': 'Para quem você não escreve há tempos?',
  },
  'prompt_relations_3': {
    'ru': 'Что тебе сегодня сказали, и ты это запомнил?',
    'en': 'What did someone say today that stayed with you?',
    'de': 'Was hat man dir heute gesagt, das hängen blieb?',
    'fr': 'Qu’est-ce qu’on t’a dit aujourd’hui qui t’est resté ?',
    'es': '¿Qué te dijeron hoy que se te quedó?',
    'it': 'Cosa ti hanno detto oggi che ti è rimasto?',
    'pt': 'O que te disseram hoje que ficou com você?',
  },
  'prompt_relations_4': {
    'ru': 'Кого сегодня хотелось обнять?',
    'en': 'Who did you want to hug today?',
    'de': 'Wen wolltest du heute umarmen?',
    'fr': 'Qui avais-tu envie de serrer dans tes bras ?',
    'es': '¿A quién querías abrazar hoy?',
    'it': 'Chi avresti voluto abbracciare oggi?',
    'pt': 'Quem você quis abraçar hoje?',
  },
  'prompt_relations_5': {
    'ru': 'Что ты сегодня не сказал вслух?',
    'en': 'What did you leave unsaid today?',
    'de': 'Was hast du heute nicht laut gesagt?',
    'fr': 'Qu’as-tu gardé pour toi aujourd’hui ?',
    'es': '¿Qué no dijiste en voz alta hoy?',
    'it': 'Cosa non hai detto ad alta voce oggi?',
    'pt': 'O que você não disse em voz alta hoje?',
  },

  // -------------------------------- Творчество --------------------------------
  'prompt_creative_1': {
    'ru': 'Что сегодня показалось красивым?',
    'en': 'What looked beautiful to you today?',
    'de': 'Was fandest du heute schön?',
    'fr': 'Qu’as-tu trouvé beau aujourd’hui ?',
    'es': '¿Qué te pareció bonito hoy?',
    'it': 'Cosa ti è sembrato bello oggi?',
    'pt': 'O que te pareceu bonito hoje?',
  },
  'prompt_creative_2': {
    'ru': 'Какая мысль пришла не вовремя?',
    'en': 'Which thought arrived at the wrong moment?',
    'de': 'Welcher Gedanke kam zur Unzeit?',
    'fr': 'Quelle pensée est venue au mauvais moment ?',
    'es': '¿Qué idea llegó a destiempo?',
    'it': 'Quale pensiero è arrivato fuori tempo?',
    'pt': 'Que pensamento veio na hora errada?',
  },
  'prompt_creative_3': {
    'ru': 'Что бы ты сфотографировал прямо сейчас?',
    'en': 'What would you photograph right now?',
    'de': 'Was würdest du jetzt fotografieren?',
    'fr': 'Que photographierais-tu maintenant ?',
    'es': '¿Qué fotografiarías ahora mismo?',
    'it': 'Cosa fotograferesti adesso?',
    'pt': 'O que você fotografaria agora?',
  },
  'prompt_creative_4': {
    'ru': 'Опиши сегодняшний день одним предложением',
    'en': 'Describe today in one sentence',
    'de': 'Beschreibe den heutigen Tag in einem Satz',
    'fr': 'Décris cette journée en une phrase',
    'es': 'Describe el día de hoy en una frase',
    'it': 'Descrivi la giornata in una frase',
    'pt': 'Descreva o dia de hoje em uma frase',
  },
  'prompt_creative_5': {
    'ru': 'Какой запах или звук сегодня запомнился?',
    'en': 'Which smell or sound stayed with you today?',
    'de': 'Welcher Geruch oder Klang ist dir geblieben?',
    'fr': 'Quelle odeur ou quel son t’est resté ?',
    'es': '¿Qué olor o sonido se te quedó hoy?',
    'it': 'Quale odore o suono ti è rimasto oggi?',
    'pt': 'Que cheiro ou som ficou com você hoje?',
  },

  // ------------------------- Экран напоминаний -------------------------
  'reminders': {
    'ru': 'Напоминания', 'en': 'Reminders', 'de': 'Erinnerungen',
    'fr': 'Rappels', 'es': 'Recordatorios', 'it': 'Promemoria',
    'pt': 'Lembretes',
  },
  'reminder_daily': {
    'ru': 'Ежедневное напоминание', 'en': 'Daily reminder',
    'de': 'Tägliche Erinnerung', 'fr': 'Rappel quotidien',
    'es': 'Recordatorio diario', 'it': 'Promemoria quotidiano',
    'pt': 'Lembrete diário',
  },
  'reminder_daily_sub': {
    'ru': 'мягко напомнить записать день',
    'en': 'a gentle nudge to write the day down',
    'de': 'sanft ans Schreiben erinnern',
    'fr': 'un rappel doux pour écrire ta journée',
    'es': 'un aviso suave para escribir el día',
    'it': 'un promemoria gentile per scrivere la giornata',
    'pt': 'um lembrete suave para escrever o dia',
  },
  'reminder_title': {
    'ru': 'Как прошёл день?', 'en': 'How was your day?',
    'de': 'Wie war dein Tag?', 'fr': 'Comment s’est passée ta journée ?',
    'es': '¿Cómo fue tu día?', 'it': 'Com’è andata la giornata?',
    'pt': 'Como foi o seu dia?',
  },
  'reminder_body': {
    'ru': 'Пара строк — и день останется с тобой',
    'en': 'A couple of lines and the day stays with you',
    'de': 'Zwei Zeilen, und der Tag bleibt dir',
    'fr': 'Deux lignes et la journée te reste',
    'es': 'Un par de líneas y el día se queda contigo',
    'it': 'Due righe e la giornata resta con te',
    'pt': 'Duas linhas e o dia fica com você',
  },
  'prompt_of_day': {
    'ru': 'Подсказка дня', 'en': 'Prompt of the day',
    'de': 'Frage des Tages', 'fr': 'Question du jour',
    'es': 'Pregunta del día', 'it': 'Domanda del giorno',
    'pt': 'Pergunta do dia',
  },
  'prompt_answer': {
    'ru': 'Ответить', 'en': 'Answer', 'de': 'Antworten', 'fr': 'Répondre',
    'es': 'Responder', 'it': 'Rispondi', 'pt': 'Responder',
  },
  'prompt_another': {
    'ru': 'Другая', 'en': 'Another', 'de': 'Andere', 'fr': 'Une autre',
    'es': 'Otra', 'it': 'Un’altra', 'pt': 'Outra',
  },
  'prompt_packs': {
    'ru': 'Наборы подсказок', 'en': 'Prompt packs', 'de': 'Fragensets',
    'fr': 'Séries de questions', 'es': 'Series de preguntas',
    'it': 'Serie di domande', 'pt': 'Conjuntos de perguntas',
  },
  'memories_morning': {
    'ru': 'Воспоминания «в этот день»', 'en': '“On this day” memories',
    'de': 'Erinnerungen „An diesem Tag“', 'fr': 'Souvenirs « Ce jour-là »',
    'es': 'Recuerdos «En este día»', 'it': 'Ricordi «In questo giorno»',
    'pt': 'Lembranças “Neste dia”',
  },
  'memories_morning_sub': {
    'ru': 'присылать по утрам', 'en': 'send them in the morning',
    'de': 'morgens schicken', 'fr': 'les envoyer le matin',
    'es': 'enviarlos por la mañana', 'it': 'mandarli la mattina',
    'pt': 'enviar de manhã',
  },
  'memories_push_body': {
    'ru': 'Загляни, что было в этот день раньше',
    'en': 'Take a look at what happened on this day before',
    'de': 'Schau, was an diesem Tag früher war',
    'fr': 'Regarde ce qui s’est passé ce jour-là',
    'es': 'Mira qué pasó en este día antes',
    'it': 'Guarda cosa è successo in questo giorno',
    'pt': 'Veja o que aconteceu neste dia antes',
  },
  'notifications_denied': {
    'ru': 'Уведомления выключены в настройках телефона',
    'en': 'Notifications are turned off in system settings',
    'de': 'Benachrichtigungen sind in den Systemeinstellungen aus',
    'fr': 'Les notifications sont désactivées dans les réglages',
    'es': 'Las notificaciones están desactivadas en el sistema',
    'it': 'Le notifiche sono disattivate nelle impostazioni',
    'pt': 'As notificações estão desligadas nas configurações',
  },
  'weekdays_short': {
    'ru': 'Пн,Вт,Ср,Чт,Пт,Сб,Вс',
    'en': 'Mon,Tue,Wed,Thu,Fri,Sat,Sun',
    'de': 'Mo,Di,Mi,Do,Fr,Sa,So',
    'fr': 'Lun,Mar,Mer,Jeu,Ven,Sam,Dim',
    'es': 'Lun,Mar,Mié,Jue,Vie,Sáb,Dom',
    'it': 'Lun,Mar,Mer,Gio,Ven,Sab,Dom',
    'pt': 'Seg,Ter,Qua,Qui,Sex,Sáb,Dom',
  },

  // ------------------- Синхронизация и экспорт -------------------
  'sync': {
    'ru': 'Синхронизация', 'en': 'Sync', 'de': 'Synchronisierung',
    'fr': 'Synchronisation', 'es': 'Sincronización', 'it': 'Sincronizzazione',
    'pt': 'Sincronização',
  },
  'sync_mode_direct': {
    'ru': 'Прямо · P2P', 'en': 'Direct · P2P', 'de': 'Direkt · P2P',
    'fr': 'Direct · P2P', 'es': 'Directo · P2P', 'it': 'Diretto · P2P',
    'pt': 'Direto · P2P',
  },
  'sync_mode_folder': {
    'ru': 'Папка · Syncthing', 'en': 'Folder · Syncthing',
    'de': 'Ordner · Syncthing', 'fr': 'Dossier · Syncthing',
    'es': 'Carpeta · Syncthing', 'it': 'Cartella · Syncthing',
    'pt': 'Pasta · Syncthing',
  },
  'sync_ready': {
    'ru': 'Готов к синхронизации', 'en': 'Ready to sync',
    'de': 'Bereit zum Synchronisieren', 'fr': 'Prêt à synchroniser',
    'es': 'Listo para sincronizar', 'it': 'Pronto a sincronizzare',
    'pt': 'Pronto para sincronizar',
  },
  'sync_waiting': {
    'ru': 'Жду второе устройство…', 'en': 'Waiting for the other device…',
    'de': 'Warte auf das andere Gerät…', 'fr': 'En attente de l’autre appareil…',
    'es': 'Esperando el otro dispositivo…', 'it': 'Aspetto l’altro dispositivo…',
    'pt': 'Aguardando o outro aparelho…',
  },
  'sync_done': {
    'ru': 'Синхронизировано · {n} изменений',
    'en': 'Synced · {n} changes',
    'de': 'Synchronisiert · {n} Änderungen',
    'fr': 'Synchronisé · {n} changements',
    'es': 'Sincronizado · {n} cambios',
    'it': 'Sincronizzato · {n} modifiche',
    'pt': 'Sincronizado · {n} mudanças',
  },
  'sync_failed': {
    'ru': 'Не получилось. Устройства в одной сети?',
    'en': 'It did not work. Are both devices on the same network?',
    'de': 'Hat nicht geklappt. Sind beide Geräte im selben Netz?',
    'fr': 'Échec. Les deux appareils sont-ils sur le même réseau ?',
    'es': 'No funcionó. ¿Ambos dispositivos en la misma red?',
    'it': 'Non ha funzionato. I dispositivi sono sulla stessa rete?',
    'pt': 'Não deu certo. Os aparelhos estão na mesma rede?',
  },
  'sync_add_device': {
    'ru': 'Добавить устройство', 'en': 'Add a device', 'de': 'Gerät hinzufügen',
    'fr': 'Ajouter un appareil', 'es': 'Añadir dispositivo',
    'it': 'Aggiungi dispositivo', 'pt': 'Adicionar aparelho',
  },
  'sync_or_phrase': {
    'ru': 'или введи фразу на другом устройстве',
    'en': 'or type the phrase on the other device',
    'de': 'oder gib die Phrase auf dem anderen Gerät ein',
    'fr': 'ou saisis la phrase sur l’autre appareil',
    'es': 'o escribe la frase en el otro dispositivo',
    'it': 'oppure scrivi la frase sull’altro dispositivo',
    'pt': 'ou digite a frase no outro aparelho',
  },
  'sync_start': {
    'ru': 'Ждать устройство', 'en': 'Wait for a device',
    'de': 'Auf Gerät warten', 'fr': 'Attendre un appareil',
    'es': 'Esperar dispositivo', 'it': 'Attendi un dispositivo',
    'pt': 'Aguardar aparelho',
  },
  'sync_scan': {
    'ru': 'Отсканировать QR', 'en': 'Scan the QR', 'de': 'QR scannen',
    'fr': 'Scanner le QR', 'es': 'Escanear el QR', 'it': 'Scansiona il QR',
    'pt': 'Escanear o QR',
  },
  'sync_scan_sub': {
    'ru': 'если QR показывает другое устройство',
    'en': 'if the other device is showing the QR',
    'de': 'wenn das andere Gerät den QR zeigt',
    'fr': 'si l’autre appareil affiche le QR',
    'es': 'si el otro dispositivo muestra el QR',
    'it': 'se il QR lo mostra l’altro dispositivo',
    'pt': 'se o outro aparelho está mostrando o QR',
  },
  'sync_folder': {
    'ru': 'Выбрать общую папку', 'en': 'Pick the shared folder',
    'de': 'Gemeinsamen Ordner wählen', 'fr': 'Choisir le dossier partagé',
    'es': 'Elegir la carpeta compartida', 'it': 'Scegli la cartella condivisa',
    'pt': 'Escolher a pasta compartilhada',
  },
  'sync_folder_sub': {
    'ru': 'ту, что уже синхронит Syncthing',
    'en': 'the one Syncthing already syncs',
    'de': 'den, den Syncthing schon synchronisiert',
    'fr': 'celui que Syncthing synchronise déjà',
    'es': 'la que Syncthing ya sincroniza',
    'it': 'quella che Syncthing già sincronizza',
    'pt': 'aquela que o Syncthing já sincroniza',
  },
  'sync_note': {
    'ru': 'Наружу уходят только изменения, зашифрованные фразой сопряжения. '
        'Сам файл базы не пересылается никогда: через общую папку он бы '
        'портился на полуслове.',
    'en': 'Only changes leave the device, encrypted with the pairing phrase. '
        'The database file itself is never sent: through a shared folder it '
        'would break mid-write.',
    'de': 'Nach außen gehen nur Änderungen, verschlüsselt mit der Phrase. '
        'Die Datenbankdatei selbst wird nie verschickt: über einen '
        'gemeinsamen Ordner würde sie mitten im Schreiben kaputtgehen.',
    'fr': 'Seuls les changements sortent, chiffrés par la phrase. Le fichier '
        'de la base n’est jamais envoyé : via un dossier partagé, il se '
        'corromprait en pleine écriture.',
    'es': 'Solo salen los cambios, cifrados con la frase. El archivo de la '
        'base nunca se envía: por una carpeta compartida se corrompería a '
        'medio escribir.',
    'it': 'Escono solo le modifiche, cifrate con la frase. Il file del '
        'database non viene mai inviato: in una cartella condivisa si '
        'romperebbe a metà scrittura.',
    'pt': 'Só as mudanças saem, cifradas com a frase. O arquivo do banco '
        'nunca é enviado: por uma pasta compartilhada ele quebraria no meio '
        'da escrita.',
  },

  'export_and_backup': {
    'ru': 'Экспорт и бэкап', 'en': 'Export and backup',
    'de': 'Export und Backup', 'fr': 'Export et sauvegarde',
    'es': 'Exportar y copia', 'it': 'Esporta e backup',
    'pt': 'Exportar e backup',
  },
  'export': {
    'ru': 'Экспорт', 'en': 'Export', 'de': 'Export', 'fr': 'Export',
    'es': 'Exportar', 'it': 'Esporta', 'pt': 'Exportar',
  },
  'export_failed': {
    'ru': 'Не получилось выгрузить', 'en': 'Export failed',
    'de': 'Export fehlgeschlagen', 'fr': 'L’export a échoué',
    'es': 'La exportación falló', 'it': 'Esportazione fallita',
    'pt': 'A exportação falhou',
  },
  'export_md_sub': {
    'ru': '.md — по записи или всё сразу',
    'en': '.md — one entry or everything',
    'de': '.md — einzeln oder alles',
    'fr': '.md — une entrée ou tout',
    'es': '.md — una entrada o todo',
    'it': '.md — una voce o tutto',
    'pt': '.md — uma anotação ou tudo',
  },
  'export_json_sub': {
    'ru': 'полная копия со всеми данными',
    'en': 'a full copy with every field',
    'de': 'vollständige Kopie mit allen Daten',
    'fr': 'copie complète avec toutes les données',
    'es': 'copia completa con todos los datos',
    'it': 'copia completa con tutti i dati',
    'pt': 'cópia completa com todos os dados',
  },
  'export_txt': {
    'ru': 'Обычный текст', 'en': 'Plain text', 'de': 'Reiner Text',
    'fr': 'Texte brut', 'es': 'Texto plano', 'it': 'Testo semplice',
    'pt': 'Texto simples',
  },
  'export_txt_sub': {
    'ru': '.txt без форматирования', 'en': '.txt without formatting',
    'de': '.txt ohne Formatierung', 'fr': '.txt sans mise en forme',
    'es': '.txt sin formato', 'it': '.txt senza formattazione',
    'pt': '.txt sem formatação',
  },
  'pdf_book': {
    'ru': 'Книга в PDF', 'en': 'A PDF book', 'de': 'Buch als PDF',
    'fr': 'Un livre en PDF', 'es': 'Un libro en PDF', 'it': 'Un libro in PDF',
    'pt': 'Um livro em PDF',
  },
  'pdf_book_sub': {
    'ru': 'Собрать красивый альбом с фото — на печать или в подарок.',
    'en': 'Make a proper album with photos — to print or to give away.',
    'de': 'Ein schönes Album mit Fotos — zum Drucken oder Verschenken.',
    'fr': 'Composer un bel album avec photos — à imprimer ou à offrir.',
    'es': 'Armar un álbum bonito con fotos — para imprimir o regalar.',
    'it': 'Comporre un bell’album con foto — da stampare o regalare.',
    'pt': 'Montar um álbum bonito com fotos — para imprimir ou presentear.',
  },
  'pdf_book_action': {
    'ru': 'Собрать книгу', 'en': 'Make the book', 'de': 'Buch bauen',
    'fr': 'Composer le livre', 'es': 'Armar el libro', 'it': 'Componi il libro',
    'pt': 'Montar o livro',
  },
  'pdf_book_title': {
    'ru': 'Мой дневник', 'en': 'My journal', 'de': 'Mein Tagebuch',
    'fr': 'Mon journal', 'es': 'Mi diario', 'it': 'Il mio diario',
    'pt': 'Meu diário',
  },
  'backup': {
    'ru': 'Бэкап', 'en': 'Backup', 'de': 'Backup', 'fr': 'Sauvegarde',
    'es': 'Copia de seguridad', 'it': 'Backup', 'pt': 'Backup',
  },
  'backup_create': {
    'ru': 'Зашифрованный бэкап', 'en': 'Encrypted backup',
    'de': 'Verschlüsseltes Backup', 'fr': 'Sauvegarde chiffrée',
    'es': 'Copia cifrada', 'it': 'Backup cifrato', 'pt': 'Backup criptografado',
  },
  'backup_restore': {
    'ru': 'Восстановить из бэкапа', 'en': 'Restore from backup',
    'de': 'Aus Backup wiederherstellen', 'fr': 'Restaurer depuis une sauvegarde',
    'es': 'Restaurar desde una copia', 'it': 'Ripristina da backup',
    'pt': 'Restaurar de um backup',
  },
  'backup_restore_sub': {
    'ru': 'заменит всё, что сейчас в дневнике',
    'en': 'replaces everything currently in the journal',
    'de': 'ersetzt alles, was jetzt im Tagebuch ist',
    'fr': 'remplace tout ce qui est dans le journal',
    'es': 'reemplaza todo lo que hay ahora en el diario',
    'it': 'sostituisce tutto quello che c’è ora nel diario',
    'pt': 'substitui tudo o que está no diário agora',
  },
  'backup_never': {
    'ru': 'ещё ни разу', 'en': 'never yet', 'de': 'noch nie',
    'fr': 'jamais encore', 'es': 'todavía nunca', 'it': 'ancora mai',
    'pt': 'ainda nunca',
  },
  'backup_last': {
    'ru': 'последний — {when}', 'en': 'last one — {when}',
    'de': 'letztes — {when}', 'fr': 'dernière — {when}',
    'es': 'última — {when}', 'it': 'ultimo — {when}',
    'pt': 'último — {when}',
  },
  'backup_phrase': {
    'ru': 'Фраза', 'en': 'Phrase', 'de': 'Phrase', 'fr': 'Phrase',
    'es': 'Frase', 'it': 'Frase', 'pt': 'Frase',
  },
  'backup_phrase_hint': {
    'ru': 'Её спросят при восстановлении. Забудешь — бэкап не открыть.',
    'en': 'You will be asked for it when restoring. Forget it and the backup '
        'stays closed.',
    'de': 'Sie wird beim Wiederherstellen abgefragt. Vergessen heißt: Backup '
        'bleibt zu.',
    'fr': 'On te la demandera à la restauration. Oubliée, la sauvegarde reste '
        'fermée.',
    'es': 'Te la pedirán al restaurar. Si la olvidas, la copia no se abre.',
    'it': 'Verrà chiesta al ripristino. Se la dimentichi, il backup resta '
        'chiuso.',
    'pt': 'Ela será pedida na restauração. Se esquecer, o backup não abre.',
  },
  'backup_phrase_ask': {
    'ru': 'Фраза, которой был зашифрован бэкап',
    'en': 'The phrase the backup was encrypted with',
    'de': 'Die Phrase, mit der das Backup verschlüsselt wurde',
    'fr': 'La phrase qui a chiffré la sauvegarde',
    'es': 'La frase con la que se cifró la copia',
    'it': 'La frase con cui è stato cifrato il backup',
    'pt': 'A frase com que o backup foi criptografado',
  },
  'backup_restored': {
    'ru': 'Дневник восстановлен. Перезапусти приложение.',
    'en': 'The journal is restored. Restart the app.',
    'de': 'Tagebuch wiederhergestellt. Starte die App neu.',
    'fr': 'Le journal est restauré. Relance l’application.',
    'es': 'El diario está restaurado. Reinicia la app.',
    'it': 'Il diario è ripristinato. Riavvia l’app.',
    'pt': 'O diário foi restaurado. Reinicie o app.',
  },
  'backup_note': {
    'ru': 'Бэкап содержит записи и вложения и шифруется фразой, а не ключом '
        'телефона — поэтому открывается на новом устройстве.',
    'en': 'The backup holds entries and attachments and is encrypted with the '
        'phrase, not the device key — so it opens on a new phone.',
    'de': 'Das Backup enthält Einträge und Anhänge und wird mit der Phrase '
        'verschlüsselt, nicht mit dem Geräteschlüssel — so öffnet es sich '
        'auch auf einem neuen Handy.',
    'fr': 'La sauvegarde contient les entrées et les pièces jointes et est '
        'chiffrée par la phrase, pas par la clé de l’appareil — elle s’ouvre '
        'donc sur un nouveau téléphone.',
    'es': 'La copia lleva entradas y adjuntos y se cifra con la frase, no con '
        'la clave del teléfono — por eso se abre en un móvil nuevo.',
    'it': 'Il backup contiene voci e allegati ed è cifrato con la frase, non '
        'con la chiave del dispositivo — così si apre su un telefono nuovo.',
    'pt': 'O backup guarda anotações e anexos e é cifrado com a frase, não '
        'com a chave do aparelho — por isso abre num telefone novo.',
  },

  'import_title': {
    'ru': 'Импорт из других дневников', 'en': 'Import from other journals',
    'de': 'Aus anderen Tagebüchern importieren', 'fr': 'Importer d’autres journaux',
    'es': 'Importar de otros diarios', 'it': 'Importa da altri diari',
    'pt': 'Importar de outros diários',
  },
  'import_row': {
    'ru': 'Выбрать файл бэкапа', 'en': 'Choose a backup file',
    'de': 'Backup-Datei wählen', 'fr': 'Choisir un fichier de sauvegarde',
    'es': 'Elegir archivo de copia', 'it': 'Scegli un file di backup',
    'pt': 'Escolher arquivo de backup',
  },
  'import_row_sub': {
    'ru': 'Diaro, StoryPad', 'en': 'Diaro, StoryPad', 'de': 'Diaro, StoryPad',
    'fr': 'Diaro, StoryPad', 'es': 'Diaro, StoryPad', 'it': 'Diaro, StoryPad',
    'pt': 'Diaro, StoryPad',
  },
  'import_done': {
    'ru': 'Перенесено записей: {n}', 'en': 'Imported {n} entries',
    'de': '{n} Einträge importiert', 'fr': '{n} entrées importées',
    'es': '{n} entradas importadas', 'it': '{n} voci importate',
    'pt': '{n} anotações importadas',
  },
  'import_nothing': {
    'ru': 'В файле не нашлось записей', 'en': 'No entries found in the file',
    'de': 'Keine Einträge in der Datei', 'fr': 'Aucune entrée dans le fichier',
    'es': 'No hay entradas en el archivo', 'it': 'Nessuna voce nel file',
    'pt': 'Nenhuma anotação no arquivo',
  },
  'import_unsupported': {
    'ru': 'Формат файла не распознан', 'en': 'Unrecognized file format',
    'de': 'Dateiformat nicht erkannt', 'fr': 'Format de fichier non reconnu',
    'es': 'Formato de archivo no reconocido', 'it': 'Formato file non riconosciuto',
    'pt': 'Formato de arquivo não reconhecido',
  },
  'import_encrypted': {
    'ru': 'Этот бэкап зашифрован паролем — импорт такого пока не поддержан',
    'en': 'This backup is password-encrypted — not supported yet',
    'de': 'Dieses Backup ist passwortverschlüsselt — noch nicht unterstützt',
    'fr': 'Cette sauvegarde est chiffrée par mot de passe — pas encore prise en charge',
    'es': 'Esta copia está cifrada con contraseña — aún no compatible',
    'it': 'Questo backup è cifrato con password — non ancora supportato',
    'pt': 'Este backup está cifrado com senha — ainda não suportado',
  },
  'import_pick_photos': {
    'ru': 'Выбрать папку с фото (можно пропустить)',
    'en': 'Pick the photos folder (optional)',
    'de': 'Fotoordner wählen (optional)', 'fr': 'Choisir le dossier photos (facultatif)',
    'es': 'Elegir carpeta de fotos (opcional)', 'it': 'Scegli la cartella foto (facoltativo)',
    'pt': 'Escolher pasta de fotos (opcional)',
  },

  'sync_manual': {
    'ru': 'Ввести руками', 'en': 'Enter by hand', 'de': 'Manuell eingeben',
    'fr': 'Saisir à la main', 'es': 'Escribir a mano',
    'it': 'Inserisci a mano', 'pt': 'Digitar manualmente',
  },
  'sync_no_camera': {
    'ru': 'На этом устройстве нет камеры для QR — нужны адрес и фраза с того, '
        'которое показывает код',
    'en': 'No camera for QR on this device — take the address and phrase from '
        'the one showing the code',
    'de': 'Kein Kamera-QR auf diesem Gerät — Adresse und Phrase vom Gerät mit '
        'dem Code nehmen',
    'fr': 'Pas de caméra pour le QR ici — prenez l’adresse et la phrase sur '
        'l’appareil qui affiche le code',
    'es': 'Este dispositivo no tiene cámara para el QR: hace falta la '
        'dirección y la frase del que muestra el código',
    'it': 'Qui non c’è una fotocamera per il QR: servono indirizzo e frase dal '
        'dispositivo che mostra il codice',
    'pt': 'Sem câmera para o QR neste aparelho — pegue o endereço e a frase no '
        'que mostra o código',
  },
  'sync_address': {
    'ru': 'Адрес устройства', 'en': 'Device address', 'de': 'Geräteadresse',
    'fr': 'Adresse de l’appareil', 'es': 'Dirección del dispositivo',
    'it': 'Indirizzo del dispositivo', 'pt': 'Endereço do aparelho',
  },
};
