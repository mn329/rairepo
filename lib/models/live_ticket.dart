enum TicketColor { blackGold, red, blue, white }

class LiveTicket {
  final String id;
  final String artistName;
  final String liveName;
  final String venue;
  final DateTime date;
  final double score;
  final TicketColor color;

  LiveTicket({
    required this.id,
    required this.artistName,
    required this.liveName,
    required this.venue,
    required this.date,
    required this.score,
    this.color = TicketColor.blackGold,
  });
}
