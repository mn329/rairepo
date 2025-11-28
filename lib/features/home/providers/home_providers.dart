import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recolle/features/home/models/recolle_category.dart';
import 'package:recolle/features/home/models/recolle_item.dart';
import 'package:recolle/models/live_ticket.dart';

// カテゴリー選択状態のプロバイダー
final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, RecolleCategory>(
      SelectedCategoryNotifier.new,
    );

class SelectedCategoryNotifier extends Notifier<RecolleCategory> {
  @override
  RecolleCategory build() {
    return RecolleCategory.live;
  }
}

// ダミーデータのプロバイダー
final recolleItemsProvider = Provider<List<RecolleItem>>((ref) {
  return [
    // Live
    RecolleItem(
      id: '1',
      title: 'LUXURY DISEASE ASIA TOUR 2023',
      subtitle: 'ONE OK ROCK',
      status: '参加済み',
      date: DateTime(2023, 11, 14),
      score: 9.8,
      color: TicketColor.blackGold,
      category: RecolleCategory.live,
    ),
    RecolleItem(
      id: '2',
      title: 'The Eras Tour',
      subtitle: 'Taylor Swift',
      status: '参加済み',
      date: DateTime(2024, 2, 7),
      score: 10.0,
      color: TicketColor.white,
      category: RecolleCategory.live,
    ),
    // Book
    RecolleItem(
      id: '3',
      title: 'プロジェクト・ヘイル・メアリー',
      subtitle: 'アンディ・ウィアー',
      status: '読了',
      date: DateTime(2024, 1, 15),
      score: 9.5,
      color: TicketColor.blue,
      category: RecolleCategory.book,
    ),
    RecolleItem(
      id: '4',
      title: '三体',
      subtitle: '劉 慈欣',
      status: '読書中',
      date: DateTime(2024, 3, 1),
      score: 8.0,
      color: TicketColor.red,
      category: RecolleCategory.book,
    ),
    // Movie
    RecolleItem(
      id: '5',
      title: 'DUNE: Part Two',
      subtitle: 'Denis Villeneuve',
      status: '視聴済み',
      date: DateTime(2024, 3, 15),
      score: 9.2,
      color: TicketColor.blackGold,
      category: RecolleCategory.movie,
    ),
    RecolleItem(
      id: '6',
      title: 'Oppenheimer',
      subtitle: 'Christopher Nolan',
      status: '視聴済み',
      date: DateTime(2024, 3, 29),
      score: 9.0,
      color: TicketColor.blackGold,
      category: RecolleCategory.movie,
    ),
  ];
});

// 選択中のカテゴリーにフィルタリングされたアイテムのプロバイダー
final filteredItemsProvider = Provider<List<RecolleItem>>((ref) {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final allItems = ref.watch(recolleItemsProvider);

  return allItems.where((item) => item.category == selectedCategory).toList();
});
