import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/features/records/models/record.dart';
import 'package:recolle/features/records/providers/records_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.record});

  final Record record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
            onPressed: () => _confirmAndDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. Large Ticket Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.network(
                record.ticketImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceLight,
                    child: const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: AppColors.textDisabled,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 3. Basic Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.gold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artist Name
                      Text(
                        record.artistOrAuthor,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        record.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.textDisabled, height: 1),
                      const SizedBox(height: 16),
                      // Date and Source
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(record.date),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (record.ticketSource != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.textDisabled,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                record.ticketSource!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 4. Reports
            if (record.type == RecordType.live) ...[
              _buildSectionTitle('セトリ'),
              _buildSetlistContent(record.setlist),
              const SizedBox(height: 24),
              _buildSectionTitle('MCメモ'),
              _buildSectionContent(record.mcMemo),
              const SizedBox(height: 24),
            ],

            _buildSectionTitle('感想'),
            _buildSectionContent(record.impressions),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String? content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        (content == null || content.isEmpty) ? '未入力' : content,
        style: TextStyle(
          color: (content == null || content.isEmpty)
              ? AppColors.textDisabled
              : AppColors.textPrimary,
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  /// セットリストを改行で分割し、番号付きで1曲ずつ表示する。
  Widget _buildSetlistContent(String? setlistText) {
    final lines = (setlistText == null || setlistText.isEmpty)
        ? <String>[]
        : setlistText.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (lines.isEmpty) {
      return _buildSectionContent(null);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lines[i],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
            if (i < lines.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('記録を削除しますか？'),
        content: Text(
          '「${record.title}」を削除すると元に戻せません。',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await Supabase.instance.client
          .from('records')
          .delete()
          .eq('id', record.id);

      if (!context.mounted) return;
      ref.invalidate(recordsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('記録を削除しました')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました。${toUserFriendlyMessage(e)}')),
        );
      }
    }
  }
}
