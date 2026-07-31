import 'package:mockito/annotations.dart';
import 'package:shrimpai_pos/services/cache.dart';

import 'mock_cache.mocks.dart';

final cache = MockCache();

@GenerateMocks([Cache])
void initializeCache() {
  Cache.instance = cache;
}
