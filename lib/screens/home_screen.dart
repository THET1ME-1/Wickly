import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../widgets/empty_state.dart';
import 'settings_screen.dart';

/// Главный экран (лента). Пока — брендовая заглушка и вход в настройки:
/// первым делом собираем оформление, темы и языки. Записи придут следующим шагом.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wickly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: tr('settings'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: EmptyState(
        icon: Icons.local_fire_department_rounded,
        title: tr('home_empty_title'),
        subtitle: tr('home_empty_sub'),
      ),
    );
  }
}
