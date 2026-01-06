import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recolle/features/records/models/record.dart';

final recordsProvider = StreamProvider<List<Record>>((ref) {
  return Supabase.instance.client
      .from('records')
      .stream(primaryKey: ['id'])
      .order('date', ascending: false)
      .map((maps) => maps.map((map) => Record.fromJson(map)).toList());
});
