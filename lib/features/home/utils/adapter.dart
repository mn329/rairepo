import 'package:recolle/models/live_ticket.dart';
import 'package:recolle/features/home/models/recolle_item.dart';

// RecolleItemをLiveTicketに変換するアダプター関数
// TicketCardを再利用するため
LiveTicket recolleItemToTicket(RecolleItem item) {
  return LiveTicket(
    id: item.id,
    artistName: item.subtitle,
    liveName: item.title,
    venue: item.status, // ステータスを表示場所に流用（暫定対応）
    date: item.date,
    score: item.score,
    color: item.color,
  );
}
