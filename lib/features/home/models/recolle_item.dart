import 'package:recolle/models/live_ticket.dart';
import 'package:recolle/features/home/models/recolle_category.dart';

// 既存のLiveTicketを拡張、または新しいモデルを作成しても良いが、
// ここでは既存のLiveTicketをベースにカテゴリーを持てるようにラッパーを作るか、
// シンプルにLiveTicketにフィールドを追加する形を模索する。
// 既存コードへの影響を最小限にするため、今回はダミーデータの生成ロジックで対応する。

class RecolleItem {
  final String id;
  final String title;
  final String subtitle; // アーティスト名や著者名など
  final String status; // 参加済み / 読了 / 視聴済み
  final DateTime date;
  final double score;
  final TicketColor color;
  final RecolleCategory category;

  RecolleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.score,
    required this.color,
    required this.category,
  });
}
