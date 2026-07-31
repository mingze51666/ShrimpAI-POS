import 'package:excel/excel.dart';
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
import 'package:shrimpai_pos/models/xfile.dart';
import 'package:shrimpai_pos/routes.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:shrimpai_pos/ui/transit/formatter/field_formatter.dart';
import 'package:shrimpai_pos/ui/transit/formatter/formatter.dart';
import 'package:shrimpai_pos/ui/transit/transit_station.dart';

import '../../../test_helpers/file_mocker.dart';
import '../../../test_helpers/translator.dart';

void main() {
  group('Transit - Excel - Export Basic', () {
    Widget buildApp() {
      return MaterialApp.router(
        routerConfig: GoRouter(
          navigatorKey: Routes.rootNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TransitStation(catalog: .exportModel, method: .excel),
            ),
          ],
        ),
      );
    }

    testWidgets('successfully', (tester) async {
      final picker = mockFilePicker();
      final path = mockFileSave(picker);

      Quantities.instance.replaceItems({'q1': Quantity(id: 'q1', name: 'q1')});
      Stock.instance.replaceItems({'i1': Ingredient(id: 'i1', name: 'i1', totalAmount: 100)});

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transit.model_export')));
      await tester.pumpAndSettle();

      expect(find.text(S.transitExportBasicSuccessExcel), findsOneWidget);
      verify(
        picker.saveFile(
          dialogTitle: anyNamed('dialogTitle'),
          fileName: '${S.transitExportBasicFileName}.xlsx',
          bytes: anyNamed('bytes'),
        ),
      );

      final excel = Excel.decodeBytes(XFile('$path/${S.transitExportBasicFileName}.xlsx').file.readAsBytesSync());
      expect(excel.sheets.keys.toList(), equals(FormattableModel.allL10nNames));

      final header = findFieldFormatter(.quantities).getHeader().map((e) => e.toString()).join(',');
      expect(
        excel[FormattableModel.quantities.l10nName]
            .row(0)
            .where((e) => e != null)
            .map((cell) => cell!.value.toString())
            .join(','),
        header,
      );
      expect(
        excel[FormattableModel.quantities.l10nName]
            .row(1)
            .where((e) => e != null)
            .map((cell) => cell!.value.toString())
            .join(','),
        'q1,1',
      );
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
