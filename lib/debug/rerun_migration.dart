import 'package:shrimpai_pos/services/database.dart';

void rerunMigration() async {
  await Database.execMigrationAction(Database.instance.db, Database.latestVersion);
}
