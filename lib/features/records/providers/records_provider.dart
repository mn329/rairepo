import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recolle/features/account/providers/auth_providers.dart';
import 'package:recolle/features/records/data/records_repository.dart';
import 'package:recolle/features/records/models/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final recordsRepositoryProvider = Provider<RecordsRepository>((ref) {
  return RecordsRepository(Supabase.instance.client);
});

final recordsProvider = StreamProvider<List<Record>>((ref) {
  final authUser = ref.watch(authUserProvider).asData?.value;
  final userId = authUser?.id;
  if (userId == null) {
    return Stream.value(const <Record>[]);
  }

  return Supabase.instance.client
      .from('records')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('date', ascending: false)
      .map((maps) => maps.map((map) => Record.fromJson(map)).toList());
});
