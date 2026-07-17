import 'package:flutter_test/flutter_test.dart';

import 'package:wickly/l10n/strings.dart';
import 'package:wickly/main.dart';

void main() {
  testWidgets('Главный экран показывает бренд и заглушку', (tester) async {
    await tester.pumpWidget(const WicklyApp());
    await tester.pump();

    // Бренд в шапке.
    expect(find.text('Wickly'), findsOneWidget);
    // Заголовок пустого состояния (текущий язык интерфейса).
    expect(find.text(tr('home_empty_title')), findsOneWidget);
  });
}
