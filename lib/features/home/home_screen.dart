import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recolle/features/detail/detail_screen.dart';
import 'package:recolle/models/record.dart';
import 'package:recolle/providers/records_provider.dart';
import 'package:recolle/theme/app_colors.dart';
import 'package:recolle/features/create/create_record_screen.dart';
import 'package:recolle/widgets/record_ticket_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Recolle',
            style: TextStyle(
              fontFamily: 'Serif', // Elegant font if available, or default
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.gold),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateRecordScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: false,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'ライブ'),
              Tab(text: '映画'),
              Tab(text: '本'),
              Tab(text: 'その他'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRecordList(context, records, RecordType.live),
            _buildRecordList(context, records, RecordType.movie),
            _buildRecordList(context, records, RecordType.book),
            _buildRecordList(context, records, RecordType.other),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordList(
      BuildContext context, List<Record> allRecords, RecordType type) {
    final filteredRecords =
        allRecords.where((record) => record.type == type).toList();

    if (filteredRecords.isEmpty) {
      return const Center(
        child: Text(
          '記録がありません',
          style: TextStyle(color: AppColors.textDisabled),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: filteredRecords.length,
      itemBuilder: (context, index) {
        final record = filteredRecords[index];
        return RecordTicketCard(
          record: record,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(record: record),
              ),
            );
          },
        );
      },
    );
  }
}

