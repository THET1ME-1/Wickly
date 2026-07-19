/// Раздел А макета: онбординг и замок дневника.
///
/// Одна запись = семь языков (ru · en · de · fr · es · it · pt).
library;

const Map<String, Map<String, String>> onboardingStrings = {
  // --------------------------- Онбординг ---------------------------
  'onb_tagline': {
    'ru': 'Тёплый дневник, который принадлежит только тебе',
    'en': 'A warm journal that belongs only to you',
    'de': 'Ein warmes Tagebuch, das nur dir gehört',
    'fr': 'Un journal chaleureux qui n’appartient qu’à toi',
    'es': 'Un diario cálido que solo te pertenece a ti',
    'it': 'Un diario accogliente che appartiene solo a te',
    'pt': 'Um diário acolhedor que pertence só a você',
  },
  'onb_f1_title': {
    'ru': 'Без аккаунта', 'en': 'No account', 'de': 'Ohne Konto',
    'fr': 'Sans compte', 'es': 'Sin cuenta', 'it': 'Senza account',
    'pt': 'Sem conta',
  },
  'onb_f1_sub': {
    'ru': 'Не нужны почта и пароль',
    'en': 'No email, no password',
    'de': 'Keine E-Mail, kein Passwort',
    'fr': 'Ni e-mail ni mot de passe',
    'es': 'Ni correo ni contraseña',
    'it': 'Niente email, niente password',
    'pt': 'Sem e-mail nem senha',
  },
  'onb_f2_title': {
    'ru': 'Всё на устройстве', 'en': 'All on your device',
    'de': 'Alles auf dem Gerät', 'fr': 'Tout sur l’appareil',
    'es': 'Todo en el dispositivo', 'it': 'Tutto sul dispositivo',
    'pt': 'Tudo no aparelho',
  },
  'onb_f2_sub': {
    'ru': 'Записи шифруются, в облако ничего не уходит',
    'en': 'Encrypted on your phone, nothing goes to a cloud',
    'de': 'Verschlüsselt auf dem Handy, nichts geht in die Cloud',
    'fr': 'Chiffré sur le téléphone, rien ne part dans le cloud',
    'es': 'Cifrado en el teléfono, nada va a la nube',
    'it': 'Cifrato sul telefono, niente va nel cloud',
    'pt': 'Criptografado no telefone, nada vai para a nuvem',
  },
  'onb_f3_title': {
    'ru': 'Синхронизация напрямую', 'en': 'Direct sync',
    'de': 'Direkte Synchronisierung', 'fr': 'Synchronisation directe',
    'es': 'Sincronización directa', 'it': 'Sincronizzazione diretta',
    'pt': 'Sincronização direta',
  },
  'onb_f3_sub': {
    'ru': 'Телефон и ноутбук видят друг друга сами',
    'en': 'Your phone and laptop find each other',
    'de': 'Handy und Laptop finden sich selbst',
    'fr': 'Ton téléphone et ton ordi se trouvent tout seuls',
    'es': 'Tu teléfono y tu portátil se encuentran solos',
    'it': 'Telefono e portatile si trovano da soli',
    'pt': 'Seu telefone e seu notebook se encontram sozinhos',
  },
  'onb_cta': {
    'ru': 'Завести дневник', 'en': 'Start a journal',
    'de': 'Tagebuch anlegen', 'fr': 'Créer un journal',
    'es': 'Crear un diario', 'it': 'Crea un diario',
    'pt': 'Criar um diário',
  },
  'onb_restore': {
    'ru': 'Восстановить из бэкапа', 'en': 'Restore from backup',
    'de': 'Aus Backup wiederherstellen', 'fr': 'Restaurer depuis une sauvegarde',
    'es': 'Restaurar desde una copia', 'it': 'Ripristina da backup',
    'pt': 'Restaurar de um backup',
  },

  // ------------------------ Замок дневника ------------------------
  'lock_title': {
    'ru': 'Дневник заперт', 'en': 'Journal locked',
    'de': 'Tagebuch gesperrt', 'fr': 'Journal verrouillé',
    'es': 'Diario bloqueado', 'it': 'Diario bloccato',
    'pt': 'Diário trancado',
  },
  'lock_wrong': {
    'ru': 'Неверный код', 'en': 'Wrong code', 'de': 'Falscher Code',
    'fr': 'Code incorrect', 'es': 'Código incorrecto', 'it': 'Codice errato',
    'pt': 'Código incorreto',
  },
  'lock_forgot': {
    'ru': 'Забыли код?', 'en': 'Forgot your code?', 'de': 'Code vergessen?',
    'fr': 'Code oublié ?', 'es': '¿Olvidaste el código?',
    'it': 'Codice dimenticato?', 'pt': 'Esqueceu o código?',
  },
  'lock_reset_msg': {
    'ru': 'Снять замок? Записи останутся на месте, новый код можно задать в настройках.',
    'en': 'Remove the lock? Your entries stay; set a new code in settings.',
    'de': 'Sperre entfernen? Einträge bleiben; neuen Code in den Einstellungen.',
    'fr': 'Retirer le verrou ? Les entrées restent ; nouveau code dans les réglages.',
    'es': '¿Quitar el bloqueo? Las entradas quedan; pon un código nuevo en ajustes.',
    'it': 'Togliere il blocco? Le voci restano; nuovo codice nelle impostazioni.',
    'pt': 'Remover o bloqueio? As anotações ficam; defina um novo código nos ajustes.',
  },
  'lock_reset_do': {
    'ru': 'Снять замок', 'en': 'Remove lock', 'de': 'Sperre entfernen',
    'fr': 'Retirer le verrou', 'es': 'Quitar bloqueo', 'it': 'Togli blocco',
    'pt': 'Remover bloqueio',
  },
  'lock_change': {
    'ru': 'Сменить код', 'en': 'Change code', 'de': 'Code ändern',
    'fr': 'Changer le code', 'es': 'Cambiar el código', 'it': 'Cambia codice',
    'pt': 'Alterar o código',
  },
  'lock_wait': {
    'ru': 'Слишком много попыток. Подождите {n} с',
    'en': 'Too many attempts. Wait {n}s',
    'de': 'Zu viele Versuche. Warte {n}s',
    'fr': 'Trop d’essais. Attendez {n}s',
    'es': 'Demasiados intentos. Espera {n}s',
    'it': 'Troppi tentativi. Attendi {n}s',
    'pt': 'Muitas tentativas. Aguarde {n}s',
  },
  'lock_biometric_reason': {
    'ru': 'Открыть дневник', 'en': 'Unlock your journal',
    'de': 'Tagebuch entsperren', 'fr': 'Déverrouiller le journal',
    'es': 'Desbloquear el diario', 'it': 'Sblocca il diario',
    'pt': 'Desbloquear o diário',
  },
  'lock_set': {
    'ru': 'Придумай код', 'en': 'Set a code', 'de': 'Code festlegen',
    'fr': 'Choisis un code', 'es': 'Crea un código', 'it': 'Imposta un codice',
    'pt': 'Crie um código',
  },
  'lock_repeat': {
    'ru': 'Повтори код', 'en': 'Repeat the code', 'de': 'Code wiederholen',
    'fr': 'Répète le code', 'es': 'Repite el código', 'it': 'Ripeti il codice',
    'pt': 'Repita o código',
  },
  'lock_mismatch': {
    'ru': 'Коды не совпали', 'en': 'Codes do not match',
    'de': 'Codes stimmen nicht überein', 'fr': 'Les codes ne correspondent pas',
    'es': 'Los códigos no coinciden', 'it': 'I codici non coincidono',
    'pt': 'Os códigos não coincidem',
  },
  'lock_use_biometrics': {
    'ru': 'Отпечаток или лицо', 'en': 'Fingerprint or face',
    'de': 'Fingerabdruck oder Gesicht', 'fr': 'Empreinte ou visage',
    'es': 'Huella o rostro', 'it': 'Impronta o volto',
    'pt': 'Digital ou rosto',
  },
};
