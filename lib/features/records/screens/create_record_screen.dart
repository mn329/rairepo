import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recolle/core/constants/field_limits.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/core/utils/japanese_date_format.dart';
import 'package:recolle/features/records/models/record.dart';
import 'package:recolle/features/records/providers/records_provider.dart';
import 'package:recolle/features/records/screens/detail_screen.dart';
import 'package:recolle/features/records/widgets/number_date_picker_sheet.dart';
import 'package:recolle/features/records/widgets/record_form_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateRecordScreen extends HookConsumerWidget {
  const CreateRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State
    final selectedType = useState<RecordType>(RecordType.live);
    final date = useState<DateTime>(DateTime.now());
    final setlist = useState<List<String>>([]);
    final selectedImage = useState<File?>(null);
    final isLoading = useState(false);

    // Controllers
    final titleController = useTextEditingController();
    final artistController = useTextEditingController();
    final sourceController = useTextEditingController();
    final currentSongController = useTextEditingController();
    final mcMemoController = useTextEditingController();
    final impressionsController = useTextEditingController();

    void tryAddSongToSetlist() {
      final line = currentSongController.text.trim();
      if (line.isEmpty) return;
      if (line.length > RecordFieldLimits.setlistSongLine) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '曲名は最大${RecordFieldLimits.setlistSongLine}文字までです。',
            ),
          ),
        );
        return;
      }
      final candidate = [...setlist.value, line].join('\n');
      if (candidate.length > RecordFieldLimits.setlistTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'セットリスト全体は最大${RecordFieldLimits.setlistTotal}文字までです。',
            ),
          ),
        );
        return;
      }
      setlist.value = [...setlist.value, line];
      currentSongController.clear();
    }

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    }

    Future<void> saveRecord() async {
      if (isLoading.value) return;

      final title = titleController.text.trim();
      final artist = artistController.text.trim();
      if (title.isEmpty || artist.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('タイトルとアーティスト名は必須です')));
        return;
      }

      if (title.length > RecordFieldLimits.title ||
          artist.length > RecordFieldLimits.artistOrAuthor) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('タイトルまたはアーティスト名が文字数上限を超えています。')),
        );
        return;
      }

      final sourceTrimmed = sourceController.text.trim();
      if (sourceTrimmed.length > RecordFieldLimits.ticketSource) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '取得元は最大${RecordFieldLimits.ticketSource}文字までです。',
            ),
          ),
        );
        return;
      }

      final setlistJoined =
          setlist.value.isEmpty ? null : setlist.value.join('\n');
      if (setlistJoined != null &&
          setlistJoined.length > RecordFieldLimits.setlistTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'セットリスト全体は最大${RecordFieldLimits.setlistTotal}文字までです。',
            ),
          ),
        );
        return;
      }

      final mcTrimmed = mcMemoController.text.trim();
      final impressionsTrimmed = impressionsController.text.trim();
      if (mcTrimmed.length > RecordFieldLimits.mcMemo ||
          impressionsTrimmed.length > RecordFieldLimits.impressions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MCメモまたは感想が文字数上限を超えています。')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('ログインしてください')));
          }
          isLoading.value = false;
          return;
        }

        final repo = ref.read(recordsRepositoryProvider);

        String? imageUrl;
        if (selectedImage.value != null) {
          debugPrint('Uploading ticket image…');
          imageUrl = await repo.uploadTicketImage(
            userId: userId,
            file: selectedImage.value!,
          );
          debugPrint('Image uploaded, URL: $imageUrl');
        }

        final record = Record(
          id: '', // DB側で生成されるため空文字
          type: selectedType.value,
          title: title,
          artistOrAuthor: artist,
          date: date.value,
          ticketImageUrl: imageUrl ?? '',
          ticketSource: sourceTrimmed.isEmpty ? null : sourceTrimmed,
          setlist: setlistJoined == null || setlistJoined.isEmpty
              ? null
              : setlistJoined,
          mcMemo: mcTrimmed.isEmpty ? null : mcTrimmed,
          impressions: impressionsTrimmed.isEmpty ? null : impressionsTrimmed,
        );

        // JSONに変換し、現在のユーザーIDを追加
        final recordData = record.toJson();
        recordData['user_id'] = userId;

        debugPrint('Inserting record: $recordData');

        final newRecord = await repo.insertRecord(recordData);
        debugPrint('Record inserted: ${newRecord.id}');

        if (context.mounted) {
          ref.invalidate(recordsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('記録を保存しました'),
              backgroundColor: AppColors.gold,
            ),
          );
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => DetailScreen(record: newRecord),
            ),
          );
        }
      } catch (e, stackTrace) {
        debugPrint('Error saving record: $e');
        debugPrint('Stack trace: $stackTrace');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(toUserFriendlyMessage(e))),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '新規登録',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isLoading.value)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: saveRecord,
              child: const Text(
                '保存',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Genre Selection
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: RecordType.values.map((type) {
                  final isSelected = selectedType.value == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(
                        type.japaneseLabel,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) selectedType.value = type;
                      },
                      selectedColor: AppColors.gold,
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.textDisabled,
                        ),
                      ),
                      // Remove checkmark
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Image Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textDisabled.withValues(alpha: 0.3),
                ),
              ),
              child: InkWell(
                onTap: pickImage,
                borderRadius: BorderRadius.circular(16),
                child: selectedImage.value != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          selectedImage.value!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'チケット画像を追加',
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Basic Info Form
            RecordFormTextField(
              controller: titleController,
              label: 'タイトル',
              icon: Icons.title,
              maxLength: RecordFieldLimits.title,
            ),
            const SizedBox(height: 16),
            RecordFormTextField(
              controller: artistController,
              label: 'アーティスト / 作者',
              icon: Icons.person_outline,
              maxLength: RecordFieldLimits.artistOrAuthor,
            ),
            const SizedBox(height: 16),

            // Date Picker (Custom Number Picker)
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.surface,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height / 3 + 50,
                      child: Column(
                        children: [
                          // Toolbar with Done button
                          Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.textDisabled.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    '決定',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Picker
                          Expanded(
                            child: NumberDatePickerSheet(
                              initialDate: date.value,
                              onDateChanged: (newDate) {
                                date.value = newDate;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textDisabled.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatJapaneseDate(
                        date.value,
                        includeWeekday: true,
                        padMonthDay: true,
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            RecordFormTextField(
              controller: sourceController,
              label: '取得元 (e+, Amazon等)',
              icon: Icons.confirmation_number_outlined,
              maxLength: RecordFieldLimits.ticketSource,
            ),

            const SizedBox(height: 32),

            // 4. Detailed Info (Conditional)
            if (selectedType.value == RecordType.live) ...[
              const Text(
                'レポート',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Setlist UI
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.list, color: AppColors.gold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'セットリスト',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // List of songs
              if (setlist.value.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textDisabled.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: setlist.value.asMap().entries.map((entry) {
                      final index = entry.key;
                      final song = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            leading: Text(
                              '${index + 1}.',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            title: Text(
                              song,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textDisabled,
                              ),
                              onPressed: () {
                                final newList = [...setlist.value];
                                newList.removeAt(index);
                                setlist.value = newList;
                              },
                            ),
                          ),
                          if (index != setlist.value.length - 1)
                            Divider(
                              height: 1,
                              color: AppColors.textDisabled.withValues(alpha: 0.2),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              // Add Song Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: currentSongController,
                      maxLength: RecordFieldLimits.setlistSongLine,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '曲名を入力',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.textDisabled.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.textDisabled.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.gold),
                        ),
                      ),
                      onSubmitted: (_) => tryAddSongToSetlist(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: tryAddSongToSetlist,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              RecordFormTextField(
                controller: mcMemoController,
                label: 'MCメモ',
                icon: Icons.mic_none,
                maxLines: 3,
                maxLength: RecordFieldLimits.mcMemo,
              ),
              const SizedBox(height: 16),
            ],

            RecordFormTextField(
              controller: impressionsController,
              label: '感想',
              icon: Icons.edit_note,
              maxLines: 5,
              maxLength: RecordFieldLimits.impressions,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
