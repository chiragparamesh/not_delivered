import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HiveStore.open();
  runApp(ProviderScope(overrides: [storeProvider.overrideWithValue(store)], child: const App()));
}
