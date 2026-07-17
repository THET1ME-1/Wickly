import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Каркас экрана настроек «ДНК» (эталон — ScoreMaster).
///
/// Экран настроек во всех приложениях строится из этих примитивов, чтобы
/// выглядеть одинаково: заголовок секции → карточка-группа со скруглением 28 →
/// строки с круглой иконкой-чипом, заголовком, подписью и трейлингом.
///
/// Специфичные для приложения пункты добавляются просто как ещё один
/// [SettingsRow] в нужную [SettingsGroup] — вид остаётся единым.
///
/// Пример:
/// ```dart
/// ListView(
///   padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
///   children: [
///     const SettingsSection('Оформление'),
///     SettingsGroup([
///       SettingsRow(
///         icon: Icons.dark_mode_rounded,
///         title: 'Тема',
///         subtitle: 'Тёмная',
///         trailing: const Icon(Icons.chevron_right_rounded),
///         onTap: _pickTheme,
///       ),
///       const SettingsDivider(),
///       SettingsRow(
///         icon: Icons.notifications_rounded,
///         title: 'Уведомления',
///         trailing: Switch(value: on, onChanged: _toggle),
///         onTap: () => _toggle(!on),
///       ),
///     ]),
///   ],
/// )
/// ```

/// Заголовок секции настроек — крупный, шрифтом заголовков.
class SettingsSection extends StatelessWidget {
  final String title;

  /// Цвет заголовка. По умолчанию — `primary`; для «опасных» секций передай
  /// `Theme.of(context).colorScheme.error`.
  final Color? color;

  const SettingsSection(this.title, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 10),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.displayFont,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: color ?? scheme.primary,
        ),
      ),
    );
  }
}

/// Скруглённая карточка-группа, в которую кладутся строки настроек.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup(this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Тонкий разделитель между строками внутри [SettingsGroup]
/// (с отступом под иконку-чип, как в эталоне).
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 76,
      endIndent: 16,
      color: scheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

/// Круглый чип-иконка в строке настроек (44×44).
class SettingsIconChip extends StatelessWidget {
  final IconData icon;
  final Color? bg;
  final Color? fg;

  const SettingsIconChip(this.icon, {super.key, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: fg ?? scheme.onPrimaryContainer),
    );
  }
}

/// Строка настроек: чип-иконка + заголовок (+ подпись) + трейлинг.
///
/// Трейлинг — обычно `Icon(Icons.chevron_right_rounded)` (переход) или `Switch`
/// (тумблер). Для тумблеров задавай и [onTap] (тап по всей строке = переключить),
/// и `onChanged` у `Switch`.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Цвет фона/иконки чипа. По умолчанию — `primaryContainer`/`onPrimaryContainer`.
  final Color? iconBg;
  final Color? iconFg;

  /// Цвет заголовка (для «опасных» строк — `error`).
  final Color? titleColor;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconBg,
    this.iconFg,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SettingsIconChip(icon, bg: iconBg, fg: iconFg),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Ряд готовых палитр цвета оформления: тапнул кружок — выбрал цвет. Выбранный
/// обведён кольцом и с контрастной галочкой.
class ColorPresetsRow extends StatelessWidget {
  final List<Color> presets;
  final Color selected;
  final ValueChanged<Color> onPick;

  /// Подпись слева (по умолчанию RU).
  final String label;

  const ColorPresetsRow({
    super.key,
    required this.presets,
    required this.selected,
    required this.onPick,
    this.label = 'Палитры',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = selected.toARGB32();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 14),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final c in presets)
                  _PresetDot(
                    color: c,
                    selected: c.toARGB32() == current,
                    onTap: () => onPick(c),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PresetDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Контрастная галочка для светлых/тёмных цветов.
    final check = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppTheme.emphasized,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 18, color: check)
            : null,
      ),
    );
  }
}
