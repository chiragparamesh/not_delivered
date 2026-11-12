import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Tiny key-value store for JSON-able values. Hive in the app, memory in tests.
abstract class KeyValueStore {
  Object? read(String key);
  Future<void> write(String key, Object? value);
  Future<void> clear();
}

/// Hive (IndexedDB on web, files on Android). Values are stored as JSON strings
/// so no type adapters or code generation are needed.
class HiveStore implements KeyValueStore {
  HiveStore(this._box);

  final Box<String> _box;
  static const boxName = 'not_delivered';

  static Future<HiveStore> open() async {
    await Hive.initFlutter();
    return HiveStore(await Hive.openBox<String>(boxName));
  }

  @override
  Object? read(String key) {
    final raw = _box.get(key);
    return raw == null ? null : jsonDecode(raw);
  }

  @override
  Future<void> write(String key, Object? value) =>
      value == null ? _box.delete(key) : _box.put(key, jsonEncode(value));

  @override
  Future<void> clear() => _box.clear();
}

class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, Object?>? initial]) : _data = {...?initial};

  final Map<String, Object?> _data;

  @override
  Object? read(String key) => _data[key] == null ? null : jsonDecode(jsonEncode(_data[key]));

  @override
  Future<void> write(String key, Object? value) async => _data[key] = value;

  @override
  Future<void> clear() async => _data.clear();
}

/// Overridden in main() with the opened HiveStore (and with MemoryStore in tests).
final storeProvider = Provider<KeyValueStore>((ref) => throw StateError('storeProvider not initialised'));
