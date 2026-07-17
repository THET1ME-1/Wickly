import 'package:flutter_test/flutter_test.dart';

import 'package:wickly/l10n/strings.dart';
import 'package:wickly/main.dart';

void main() {
  testWidgets('Главный экран: бренд и пустое состояние', (tester) async {
    // Без открытой базы репозиторий отдаёт пустой поток (гард) → показывается
    // пустое состояние; БД во flutter_tester не трогаем.
    await tester.pumpWidget(const WicklyApp());
    await tester.pump();

    expect(find.text('Wickly'), findsOneWidget);
    expect(find.text(tr('home_empty_title')), findsOneWidget);
  });
}
