import 'package:flutter/material.dart';

import '../data/journal_lock.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../theme/feedback.dart';
import 'sheet_scaffold.dart';

/// Пароль, придуманный человеком: хэш и соль к нему.
class JournalPassword {
  final String hash;
  final String salt;

  const JournalPassword(this.hash, this.salt);

  factory JournalPassword.of(String password) {
    final salt = JournalLock.newSalt();
    return JournalPassword(JournalLock.hashPassword(password, salt), salt);
  }
}

/// Придумать пароль дневника: два поля, второе сверяется с первым.
///
/// Своё поле ввода, а не код приложения: код впускает в приложение, и просить
/// его второй раз на входе в дневник — значит не запирать ничего.
Future<JournalPassword?> askNewJournalPassword(
  BuildContext context, {
  String? note,
}) =>
    showWicklySheet<JournalPassword>(
      context,
      builder: (_) => _PasswordSheet(mode: _Mode.create, note: note),
    );

/// Чем кончился спрос пароля.
enum JournalAccess {
  /// Пароль подошёл.
  granted,

  /// Лист закрыли, не введя пароль.
  denied,

  /// Пароль забыт — замок с дневника снимают целиком.
  lockRemoved,
}

/// Спросить пароль запертого дневника.
Future<JournalAccess> askJournalPassword(
  BuildContext context,
  Journal journal,
) async {
  final result = await showWicklySheet<JournalAccess>(
    context,
    builder: (_) => _PasswordSheet(mode: _Mode.check, journal: journal),
  );
  return result ?? JournalAccess.denied;
}

enum _Mode { create, check }

class _PasswordSheet extends StatefulWidget {
  final _Mode mode;
  final Journal? journal;

  /// Строка над полем — например, что у старого дневника пароля ещё нет.
  final String? note;

  const _PasswordSheet({required this.mode, this.journal, this.note});

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  final _firstFocus = FocusNode();
  final _secondFocus = FocusNode();

  String? _error;
  bool _visible = false;

  /// Показываем ли подтверждение снятия замка («Забыли пароль?»).
  bool _confirmingReset = false;

  bool get _creating => widget.mode == _Mode.create;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    _firstFocus.dispose();
    _secondFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _first.text;

    if (!_creating) {
      if (JournalLock.matches(widget.journal!, password)) {
        Haptics.commit();
        Navigator.of(context).pop(JournalAccess.granted);
        return;
      }
      Haptics.warn();
      setState(() => _error = tr('journal_password_wrong'));
      _first.clear();
      _firstFocus.requestFocus();
      return;
    }

    if (password.length < JournalLock.minLength) {
      Haptics.warn();
      setState(() => _error =
          trf('journal_password_short', {'n': '${JournalLock.minLength}'}));
      return;
    }
    if (password != _second.text) {
      Haptics.warn();
      setState(() => _error = tr('journal_password_mismatch'));
      _second.clear();
      _secondFocus.requestFocus();
      return;
    }
    Haptics.commit();
    Navigator.of(context).pop(JournalPassword.of(password));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_confirmingReset) return _resetConfirm(context);

    return Padding(
      // Лист поднимается над клавиатурой: поле ввода — это весь лист, и уйти
      // под неё ему некуда.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SheetScaffold(
        title: _creating ? tr('journal_password') : tr('journal_password_enter'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: FilledButton(
          onPressed: _submit,
          child: Text(_creating ? tr('save') : tr('journal_unlock')),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.note != null) ...[
                Text(
                  widget.note!,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!_creating)
                Text(
                  widget.journal?.name ?? '',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              if (!_creating) const SizedBox(height: 12),
              TextField(
                controller: _first,
                focusNode: _firstFocus,
                autofocus: true,
                obscureText: !_visible,
                textInputAction:
                    _creating ? TextInputAction.next : TextInputAction.done,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) =>
                    _creating ? _secondFocus.requestFocus() : _submit(),
                decoration: InputDecoration(
                  hintText: _creating
                      ? tr('journal_password_new')
                      : tr('journal_password_enter'),
                  errorText: _creating ? null : _error,
                  suffixIcon: IconButton(
                    icon: Icon(_visible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () => setState(() => _visible = !_visible),
                  ),
                ),
              ),
              if (_creating) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _second,
                  focusNode: _secondFocus,
                  obscureText: !_visible,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: tr('journal_password_repeat'),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('journal_password_sub'),
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 12.5,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              // Забытый пароль не должен запирать записи навсегда: он их не
              // шифрует, а только закрывает вход. Снятие замка честнее, чем
              // дневник, в который никто уже не войдёт.
              if (!_creating)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _confirmingReset = true),
                    child: Text(tr('journal_forgot')),
                  ),
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  /// Подтверждение снятия замка — внутри листа, без окна поверх окна.
  Widget _resetConfirm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SheetScaffold(
      title: tr('journal_forgot'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => setState(() => _confirmingReset = false),
      ),
      bottom: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
        ),
        onPressed: () {
          Haptics.warn();
          Navigator.of(context).pop(JournalAccess.lockRemoved);
        },
        child: Text(tr('lock_reset_do')),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          tr('journal_reset_msg'),
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 13.5,
            height: 1.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
