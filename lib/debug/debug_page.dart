import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/style/pop_button.dart';
import 'package:shrimpai_pos/debug/random_gen_order.dart';
import 'package:shrimpai_pos/debug/rerun_migration.dart';
import 'package:shrimpai_pos/services/cache.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug'), leading: const PopButton()),
      body: ListView(
        key: const Key('debug.list'),
        children: [
          ListTile(
            title: const Text('Generate orders'),
            trailing: const Icon(Icons.add_outlined),
            onTap: goGenerateRandomOrders(context),
          ),
          ListTile(
            title: const Text('Cache Reset'),
            trailing: const Icon(Icons.clear_all_outlined),
            onTap: Cache.instance.reset,
          ),
          const ListTile(
            title: Text('Migrate DB Again'),
            trailing: Icon(Icons.refresh_outlined),
            onTap: rerunMigration,
          ),
        ],
      ),
    );
  }
}
