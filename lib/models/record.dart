enum RecordType { live, movie, book, other }

class Record {
  final String id;
  final RecordType type;
  final String title;
  final String artistOrAuthor;
  final DateTime date;
  final String ticketImageUrl;
  final String? ticketSource; // e+, LawTicket, etc.
  final String? setlist;
  final String? mcMemo;
  final String? impressions;

  const Record({
    required this.id,
    required this.type,
    required this.title,
    required this.artistOrAuthor,
    required this.date,
    required this.ticketImageUrl,
    this.ticketSource,
    this.setlist,
    this.mcMemo,
    this.impressions,
  });

  String get typeLabel {
    switch (type) {
      case RecordType.live:
        return 'ライブ';
      case RecordType.movie:
        return '映画';
      case RecordType.book:
        return '本';
      case RecordType.other:
        return 'その他';
    }
  }
}
