import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/map_screen.dart';

import 'harness.dart';
import 'samples.dart';

void main() {
  testWidgets('Карта записей во всех темах', (tester) async {
    final entries = [
      Samples.entry(
        id: 'p1',
        title: 'Вечер у реки',
        at: DateTime(2026, 7, 17, 21, 10),
        mood: 4,
        place: 'Набережная',
        weather: 'ясно',
      ).copyWith(lat: 59.9386, lon: 30.3141),
      Samples.entry(
        id: 'p2',
        title: 'Утро там же',
        at: DateTime(2026, 7, 10, 8, 0),
        mood: 5,
        place: 'Набережная',
        weather: 'ясно',
      ).copyWith(lat: 59.9387, lon: 30.3142),
      Samples.entry(
        id: 'p3',
        title: 'Парк',
        at: DateTime(2026, 7, 5, 15, 0),
        mood: 3,
        place: 'Парк',
        weather: 'облачно',
      ).copyWith(lat: 59.9450, lon: 30.3300),
    ];
    await Harness.shoot(
      tester,
      'map',
      () => MapView(places: groupIntoPlaces(entries)),
    );
  });
}
