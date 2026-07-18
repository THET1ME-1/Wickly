import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/catalog_manager_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('Менеджер эмоций и действий', (tester) async {
    await Harness.shoot(
      tester,
      'catalog_manager',
      () => const CatalogManagerScreen(),
    );
  });
}
