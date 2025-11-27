import 'package:flutter/material.dart';
import 'models/live_ticket.dart';
import 'widgets/ticket_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Toggle this to see empty state
  final bool _isEmpty = false;

  final List<LiveTicket> _tickets = [
    LiveTicket(
      id: '1',
      artistName: 'ONE OK ROCK',
      liveName: 'LUXURY DISEASE ASIA TOUR 2023',
      venue: 'Tokyo Dome',
      date: DateTime(2023, 11, 14), // Tue
      score: 9.8,
      color: TicketColor.blackGold,
    ),
    LiveTicket(
      id: '2',
      artistName: 'Taylor Swift',
      liveName: 'The Eras Tour',
      venue: 'Tokyo Dome',
      date: DateTime(2024, 2, 7), // Wed
      score: 10.0,
      color: TicketColor.white,
    ),
    LiveTicket(
      id: '3',
      artistName: 'King Gnu',
      liveName: 'THE GREATEST UNKNOWN',
      venue: 'Sapporo Dome',
      date: DateTime(2024, 3, 23), // Sat
      score: 9.5,
      color: TicketColor.red,
    ),
    LiveTicket(
      id: '4',
      artistName: 'YOASOBI',
      liveName: 'ZEPP TOUR 2024',
      venue: 'Zepp Haneda',
      date: DateTime(2024, 1, 25), // Thu
      score: 8.5,
      color: TicketColor.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Background color #0A0A0A
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Report',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        return TicketCard(
                          ticket: ticket,
                          onTap: () {
                            // TODO: Navigate to detail
                            debugPrint('Tapped ${ticket.artistName}');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add ticket
        },
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'まだチケットがありません',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD4AF37)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'ライブを登録する',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
