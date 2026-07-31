import 'package:flutter_test/flutter_test.dart';
import 'package:shrimpai_pos/debug/rerun_migration.dart';
import 'package:shrimpai_pos/services/database.dart';
import 'package:shrimpai_pos/services/database_migration_actions.dart';

import '../services/database_test.mocks.dart';

void main() {
  group('DEBUG', () {
    test('Rerun the migration test', () async {
      dbMigrationActions.remove(Database.latestVersion);
      Database.instance.db = MockDatabase();

      rerunMigration();
    });
  });
}
