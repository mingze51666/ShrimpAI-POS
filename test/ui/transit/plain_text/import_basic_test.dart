import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shrimpai_pos/models/repository/menu.dart';
import 'package:shrimpai_pos/models/repository/order_attributes.dart';
import 'package:shrimpai_pos/models/repository/quantities.dart';
import 'package:shrimpai_pos/models/repository/replenisher.dart';
import 'package:shrimpai_pos/models/repository/stock.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:shrimpai_pos/ui/transit/exporter/plain_text_exporter.dart';
import 'package:shrimpai_pos/ui/transit/transit_station.dart';

import '../../../mocks/mock_storage.dart';
import '../../../test_helpers/translator.dart';

void main() {
  group('Transit - Plain Text - Import Basic', () {
    Widget buildApp() {
      return const MaterialApp(
        home: TransitStation(exporter: PlainTextExporter(), catalog: .importModel, method: .plainText),
      );
    }

    testWidgets('wrong text', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text(S.transitImportBtnPlainTextAction));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('transit.pt_text')), 'some-text');
      await tester.tap(find.byKey(const Key('transit.pt_preview')));
      await tester.pumpAndSettle();

      expect(find.text(S.transitImportErrorPlainTextNotFound), findsOneWidget);
    });

    testWidgets('successfully', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text(S.transitImportBtnPlainTextAction));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('transit.pt_text')),
        '${S.transitFormatTextQuantitiesHeader(1)}\n\n'
        '${S.transitFormatTextQuantitiesQuantity('1', 'q1', '1')}',
      );
      await tester.tap(find.byKey(const Key('transit.pt_preview')));
      await tester.pumpAndSettle();

      // allow import
      await tester.tap(find.byKey(const Key('transit.import.confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_dialog.confirm')));
      await tester.pumpAndSettle();

      // quantities won't reset to avoid changing menu settings.
      verifyNever(storage.reset(any));
      verify(storage.add(any, any, {'name': 'q1', 'defaultProportion': 1}));
    });

    setUpAll(() {
      initializeTranslator();
      initializeStorage();
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
