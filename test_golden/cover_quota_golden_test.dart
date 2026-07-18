// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/services/web_photo_service.dart';
import 'package:wickly/theme/wickly_design.dart';
import 'package:wickly/widgets/cover_sheet.dart';

import 'harness.dart';

void main() {
  // Плашка живёт в прокручиваемом листе выбора обложки — снимаем её там же,
  // иначе она растянется на всю высоту стенда и снимок соврёт.
  Widget stage() => Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: WicklyDesign.screenPad,
            vertical: 40,
          ),
          children: const [CoverQuotaBadge()],
        ),
      );

  testWidgets('Плашка лимита: обычный остаток', (tester) async {
    WebPhotoService.quota.value = const WebPhotoQuota(
      leftThisMinute: 19,
      leftToday: 187,
      perMinute: 20,
      perDay: 200,
    );
    await Harness.shoot(tester, 'cover_quota', stage);
  });

  testWidgets('Плашка лимита: на исходе', (tester) async {
    WebPhotoService.quota.value = const WebPhotoQuota(
      leftThisMinute: 12,
      leftToday: 14,
      perMinute: 20,
      perDay: 200,
    );
    await Harness.shoot(tester, 'cover_quota_low', stage);
  });

  testWidgets('Плашка лимита: исчерпан', (tester) async {
    WebPhotoService.quota.value = const WebPhotoQuota(
      leftThisMinute: 0,
      leftToday: 0,
      perMinute: 20,
      perDay: 200,
      exhausted: true,
    );
    await Harness.shoot(tester, 'cover_quota_out', stage);
  });
}
