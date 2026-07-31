import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:shrimpai_pos/models/repository/menu.dart';
import 'package:shrimpai_pos/models/repository/order_attributes.dart';
import 'package:shrimpai_pos/models/repository/quantities.dart';
import 'package:shrimpai_pos/models/repository/replenisher.dart';
import 'package:shrimpai_pos/models/repository/stock.dart';
import 'package:shrimpai_pos/models/stock/ingredient.dart';
import 'package:shrimpai_pos/models/stock/quantity.dart';
import 'package:shrimpai_pos/routes.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:shrimpai_pos/ui/transit/formatter/field_formatter.dart';
import 'package:shrimpai_pos/ui/transit/formatter/formatter.dart';
import 'package:shrimpai_pos/ui/transit/transit_station.dart';

import '../../../test_helpers/file_mocker.dart';
import '../../../test_helpers/translator.dart';

void main() {
  group('Transit - CSV - Export Basic', () {
    Widget buildApp() {
      return MaterialApp.router(
        routerConfig: GoRouter(
          navigatorKey: Routes.rootNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TransitStation(catalog: .exportModel, method: .csv),
            ),
          ],
        ),
      );
    }

    testWidgets('successfully', (tester) async {
      final picker = mockFilePicker();
      mockFileSave(picker);

      Quantities.instance.replaceItems({'q1': Quantity(id: 'q1', name: 'q1')});
      Stock.instance.replaceItems({'i1': Ingredient(id: 'i1', name: 'i1', totalAmount: 100)});

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transit.model_export')));
      await tester.pumpAndSettle();

      final header1 = findFieldFormatter(.stock).getHeader().map((e) => e.toString()).join(',');
      final header2 = findFieldFormatter(.quantities).getHeader().map((e) => e.toString()).join(',');
      verify(
        picker.saveFile(
          dialogTitle: anyNamed('dialogTitle'),
          fileName: '${S.transitExportBasicFileName}.csv',
          bytes: utf8.encode('$header1\ni1,0.0,100,,1.0\n\n$header2\nq1,1'),
        ),
      );
    });

    testWidgets('abort saving', (tester) async {
      Quantities.instance.replaceItems({'q1': Quantity(id: 'q1', name: 'q1')});
      Stock.instance.replaceItems({'i1': Ingredient(id: 'i1', name: 'i1')});

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transit.model_picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transit.model_picker.menu')), warnIfMissed: false);
      await tester.pumpAndSettle();

      // empty data export, won't need picker
      await tester.tap(find.byKey(const Key('transit.model_export')));
      await tester.pumpAndSettle();

      expect(find.text(S.transitExportBasicSuccessCsv), findsNothing);

      final picker = mockFilePicker();
      mockFileSave(picker, canceled: true);

      // change by tab
      await tester.tap(find.text(FormattableModel.quantities.l10nName));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transit.model_export')));
      await tester.pumpAndSettle();

      expect(find.text(S.transitExportBasicSuccessCsv), findsNothing);
    });

    setUpAll(() {
      initializeTranslator();
      initializeFileSystem();
    });

    setUp(() {
      Menu();
      Stock();
      Quantities();
      Replenisher();
      OrderAttributes();
    });
  });
}
