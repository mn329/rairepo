import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:recolle/features/records/models/record.dart';

/// オンライン同期時に保存し、オフライン閲覧用に読み出すローカルキャッシュ。
class RecordsLocalCache {
  Future<File> _fileForUser(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'records_cache_$userId.json'));
  }

  Future<void> save(String userId, List<Record> records) async {
    final file = await _fileForUser(userId);
    final list = records
        .map((r) => <String, dynamic>{...r.toJson(), 'id': r.id})
        .toList();
    await file.writeAsString(jsonEncode(list));
  }

  Future<List<Record>> load(String userId) async {
    try {
      final file = await _fileForUser(userId);
      if (!await file.exists()) {
        return const [];
      }
      final text = await file.readAsString();
      if (text.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(text) as List<dynamic>;
      return decoded
          .map((e) => Record.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
