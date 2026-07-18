import 'dart:convert';

import 'package:crypto/crypto.dart' as hash;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Настройки самого устройства — то, что **не** синкается между телефоном и
/// ноутбуком: пройден ли онбординг, код замка, стартовый экран, размер шрифта,
/// расписание напоминаний.
///
/// Записи и каталог живут в CRDT-базе и ездят между устройствами; настройки
/// устройства остаются на устройстве, поэтому им хватает `shared_preferences`.
class AppPrefs extends ChangeNotifier {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  static const _kOnboarded = 'onboarding_done';
  static const _kPinHash = 'lock_pin_hash';
  static const _kPinSalt = 'lock_pin_salt';
  static const _kBiometrics = 'lock_biometrics';
  static const _kLockTimeout = 'lock_timeout_sec';
  static const _kStartScreen = 'start_screen';
  static const _kTextScale = 'text_scale';
  static const _kReminder = 'reminder_enabled';
  static const _kReminderTime = 'reminder_minutes';
  static const _kReminderDays = 'reminder_days';
  static const _kPromptPack = 'prompt_pack';
  static const _kMemories = 'memories_enabled';
  static const _kAutoBackup = 'autobackup_enabled';
  static const _kAutoBackupAt = 'autobackup_last';
  static const _kLastSyncAt = 'last_sync_at';
  static const _kLastJournal = 'last_journal_id';
  static const _kDeviceName = 'device_name';
  static const _kAutoContext = 'auto_context';
  static const _kCoverBanner = 'cover_banner';
  static const _kUpdateCheckedAt = 'update_checked_at';
  static const _kSkippedUpdate = 'update_skipped';

  SharedPreferences? _p;

  bool _onboarded = false;
  String? _pinHash;
  String? _pinSalt;
  bool _biometrics = false;
  int _lockTimeoutSec = 0;
  String _startScreen = 'feed';
  double _textScale = 1;
  bool _reminder = false;
  int _reminderMinutes = 21 * 60;
  List<int> _reminderDays = const [1, 2, 3, 4, 5, 6, 7];
  String _promptPack = 'gratitude';
  bool _memories = true;
  bool _autoBackup = false;
  int _autoBackupAt = 0;
  int _lastSyncAt = 0;
  String? _lastJournalId;
  String _deviceName = '';
  bool _autoContext = true;
  bool _coverBanner = true;
  int _updateCheckedAt = 0;
  String _skippedUpdate = '';

  bool get onboarded => _onboarded;
  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;
  bool get biometrics => _biometrics;

  /// Через сколько секунд в фоне дневник снова запирается. 0 — сразу.
  int get lockTimeoutSec => _lockTimeoutSec;
  String get startScreen => _startScreen;
  double get textScale => _textScale;
  bool get reminder => _reminder;

  /// Время напоминания в минутах от полуночи.
  int get reminderMinutes => _reminderMinutes;
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderMinutes ~/ 60, minute: _reminderMinutes % 60);

  /// Дни недели напоминания, 1 = понедельник.
  List<int> get reminderDays => _reminderDays;
  String get promptPack => _promptPack;
  bool get memories => _memories;
  bool get autoBackup => _autoBackup;

  /// Когда последний раз обменивались с другим устройством. Раньше на экране
  /// синхронизации показывалось время БЭКАПА — разные события, одна подпись.
  DateTime? get lastSyncAt => _lastSyncAt == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_lastSyncAt);
  DateTime? get autoBackupAt => _autoBackupAt == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_autoBackupAt);
  String? get lastJournalId => _lastJournalId;
  String get deviceName => _deviceName;

  /// Подставлять ли место и погоду в новую запись.
  bool get autoContext => _autoContext;

  /// Показывать ли новым записям обложку-шапку. У каждой записи есть свой
  /// выбор — это лишь то, с чего она начинает.
  bool get coverBanner => _coverBanner;

  /// Когда в последний раз сами ходили на GitHub за обновлением.
  int get updateCheckedAt => _updateCheckedAt;

  /// Версия, от которой человек отмахнулся кнопкой «Позже».
  String get skippedUpdate => _skippedUpdate;

  Future<void> load() async {
    final p = _p = await SharedPreferences.getInstance();
    _onboarded = p.getBool(_kOnboarded) ?? false;
    _pinHash = p.getString(_kPinHash);
    _pinSalt = p.getString(_kPinSalt);
    _biometrics = p.getBool(_kBiometrics) ?? false;
    _lockTimeoutSec = p.getInt(_kLockTimeout) ?? 0;
    _startScreen = p.getString(_kStartScreen) ?? 'feed';
    _textScale = p.getDouble(_kTextScale) ?? 1;
    _reminder = p.getBool(_kReminder) ?? false;
    _reminderMinutes = p.getInt(_kReminderTime) ?? 21 * 60;
    _reminderDays = (p.getStringList(_kReminderDays) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    if (_reminderDays.isEmpty) _reminderDays = const [1, 2, 3, 4, 5, 6, 7];
    _promptPack = p.getString(_kPromptPack) ?? 'gratitude';
    _memories = p.getBool(_kMemories) ?? true;
    _autoBackup = p.getBool(_kAutoBackup) ?? false;
    _autoBackupAt = p.getInt(_kAutoBackupAt) ?? 0;
    _lastSyncAt = p.getInt(_kLastSyncAt) ?? 0;
    _lastJournalId = p.getString(_kLastJournal);
    _deviceName = p.getString(_kDeviceName) ?? '';
    _autoContext = p.getBool(_kAutoContext) ?? true;
    _coverBanner = p.getBool(_kCoverBanner) ?? true;
    _updateCheckedAt = p.getInt(_kUpdateCheckedAt) ?? 0;
    _skippedUpdate = p.getString(_kSkippedUpdate) ?? '';
    notifyListeners();
  }

  Future<void> setOnboarded(bool v) async {
    _onboarded = v;
    await _p?.setBool(_kOnboarded, v);
    notifyListeners();
  }

  // ------------------------------ Замок ------------------------------

  /// Хранится не сам код, а его соль и хэш: даже с доступом к настройкам
  /// подобрать четыре цифры без соли не выйдет мгновенно.
  Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    _pinSalt = salt;
    _pinHash = _hashPin(pin, salt);
    await _p?.setString(_kPinSalt, salt);
    await _p?.setString(_kPinHash, _pinHash!);
    notifyListeners();
  }

  Future<void> clearPin() async {
    _pinHash = null;
    _pinSalt = null;
    _biometrics = false;
    await _p?.remove(_kPinHash);
    await _p?.remove(_kPinSalt);
    await _p?.setBool(_kBiometrics, false);
    notifyListeners();
  }

  bool checkPin(String pin) =>
      hasPin && _hashPin(pin, _pinSalt ?? '') == _pinHash;

  static String _hashPin(String pin, String salt) =>
      hash.sha256.convert(utf8.encode('wickly:$salt:$pin')).toString();

  Future<void> setBiometrics(bool v) async {
    _biometrics = v;
    await _p?.setBool(_kBiometrics, v);
    notifyListeners();
  }

  Future<void> setLockTimeout(int seconds) async {
    _lockTimeoutSec = seconds;
    await _p?.setInt(_kLockTimeout, seconds);
    notifyListeners();
  }

  // ---------------------------- Интерфейс ----------------------------

  Future<void> setStartScreen(String v) async {
    _startScreen = v;
    await _p?.setString(_kStartScreen, v);
    notifyListeners();
  }

  Future<void> setTextScale(double v) async {
    _textScale = v;
    await _p?.setDouble(_kTextScale, v);
    notifyListeners();
  }

  // --------------------------- Напоминания ---------------------------

  Future<void> setReminder(bool v) async {
    _reminder = v;
    await _p?.setBool(_kReminder, v);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay t) async {
    _reminderMinutes = t.hour * 60 + t.minute;
    await _p?.setInt(_kReminderTime, _reminderMinutes);
    notifyListeners();
  }

  Future<void> setReminderDays(List<int> days) async {
    _reminderDays = days.toList()..sort();
    await _p?.setStringList(
        _kReminderDays, _reminderDays.map((d) => '$d').toList());
    notifyListeners();
  }

  Future<void> setPromptPack(String v) async {
    _promptPack = v;
    await _p?.setString(_kPromptPack, v);
    notifyListeners();
  }

  Future<void> setMemories(bool v) async {
    _memories = v;
    await _p?.setBool(_kMemories, v);
    notifyListeners();
  }

  // ------------------------------ Прочее ------------------------------

  Future<void> setAutoBackup(bool v) async {
    _autoBackup = v;
    await _p?.setBool(_kAutoBackup, v);
    notifyListeners();
  }

  Future<void> markSynced(DateTime at) async {
    _lastSyncAt = at.millisecondsSinceEpoch;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt(_kLastSyncAt, _lastSyncAt);
  }

  Future<void> markAutoBackup(DateTime at) async {
    _autoBackupAt = at.millisecondsSinceEpoch;
    await _p?.setInt(_kAutoBackupAt, _autoBackupAt);
    notifyListeners();
  }

  Future<void> setLastJournal(String id) async {
    _lastJournalId = id;
    await _p?.setString(_kLastJournal, id);
    notifyListeners();
  }

  Future<void> setDeviceName(String v) async {
    _deviceName = v;
    await _p?.setString(_kDeviceName, v);
    notifyListeners();
  }

  Future<void> setAutoContext(bool v) async {
    _autoContext = v;
    await _p?.setBool(_kAutoContext, v);
    notifyListeners();
  }

  Future<void> setCoverBanner(bool v) async {
    _coverBanner = v;
    await _p?.setBool(_kCoverBanner, v);
    notifyListeners();
  }

  Future<void> setUpdateCheckedAt(int msSinceEpoch) async {
    _updateCheckedAt = msSinceEpoch;
    await _p?.setInt(_kUpdateCheckedAt, msSinceEpoch);
  }

  Future<void> setSkippedUpdate(String version) async {
    _skippedUpdate = version;
    await _p?.setString(_kSkippedUpdate, version);
  }
}
