import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/features/records/models/record.dart';
import 'package:recolle/features/records/providers/records_provider.dart';
import 'package:recolle/features/records/screens/detail_screen.dart';
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

    // Helper for date formatting
    String formatDate(DateTime d) {
      const weekDays = ['月', '火', '水', '木', '金', '土', '日'];
      final w = weekDays[d.weekday - 1];
      return '${d.year}年${d.month.toString().padLeft(2, '0')}月${d.day.toString().padLeft(2, '0')}日 ($w)';
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

      if (titleController.text.isEmpty || artistController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('タイトルとアーティスト名は必須です')));
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

        String? imageUrl;
        if (selectedImage.value != null) {
          final baseName =
              '${DateTime.now().millisecondsSinceEpoch}_${selectedImage.value!.path.split('/').last}';
          final storagePath = '$userId/$baseName';
          debugPrint('Uploading image: $storagePath');
          await Supabase.instance.client.storage
              .from('ticket-images')
              .upload(storagePath, selectedImage.value!);

          imageUrl = Supabase.instance.client.storage
              .from('ticket-images')
              .getPublicUrl(storagePath);
          debugPrint('Image uploaded, URL: $imageUrl');
        }

        final record = Record(
          id: '', // DB側で生成されるため空文字
          type: selectedType.value,
          title: titleController.text,
          artistOrAuthor: artistController.text,
          date: date.value,
          ticketImageUrl: imageUrl ?? '',
          ticketSource: sourceController.text.isEmpty
              ? null
              : sourceController.text,
          setlist: setlist.value.isEmpty ? null : setlist.value.join('\n'),
          mcMemo: mcMemoController.text.isEmpty ? null : mcMemoController.text,
          impressions: impressionsController.text.isEmpty
              ? null
              : impressionsController.text,
        );

        // JSONに変換し、現在のユーザーIDを追加
        final recordData = record.toJson();
        recordData['user_id'] = userId;

        debugPrint('Inserting record: $recordData');

        final inserted = await Supabase.instance.client
            .from('records')
            .insert(recordData)
            .select()
            .single();

        final newRecord = Record.fromJson(inserted);
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
                        _getTypeLabel(type),
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
                  color: AppColors.textDisabled.withOpacity(0.3),
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
                            color: AppColors.gold.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'チケット画像を追加',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Basic Info Form
            _buildTextField(
              controller: titleController,
              label: 'タイトル',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: artistController,
              label: 'アーティスト / 作者',
              icon: Icons.person_outline,
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
                                  color: AppColors.textDisabled.withOpacity(
                                    0.2,
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
                            child: _NumberDatePicker(
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
                    color: AppColors.textDisabled.withOpacity(0.3),
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
                      formatDate(date.value),
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
            _buildTextField(
              controller: sourceController,
              label: '取得元 (e+, Amazon等)',
              icon: Icons.confirmation_number_outlined,
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
                      color: AppColors.textDisabled.withOpacity(0.3),
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
                              color: AppColors.textDisabled.withOpacity(0.2),
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
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '曲名を入力',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
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
                            color: AppColors.textDisabled.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.textDisabled.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.gold),
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setlist.value = [...setlist.value, value];
                          currentSongController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (currentSongController.text.isNotEmpty) {
                        setlist.value = [
                          ...setlist.value,
                          currentSongController.text,
                        ];
                        currentSongController.clear();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildTextField(
                controller: mcMemoController,
                label: 'MCメモ',
                icon: Icons.mic_none,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],

            _buildTextField(
              controller: impressionsController,
              label: '感想',
              icon: Icons.edit_note,
              maxLines: 5,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(RecordType type) {
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
        prefixIcon: Icon(
          icon,
          color: AppColors.gold.withOpacity(0.7),
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textDisabled.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        alignLabelWithHint: true,
      ),
    );
  }
}

class _NumberDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;

  const _NumberDatePicker({
    required this.initialDate,
    required this.onDateChanged,
  });

  @override
  State<_NumberDatePicker> createState() => _NumberDatePickerState();
}

class _NumberDatePickerState extends State<_NumberDatePicker> {
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  final int _minYear = 2000;
  final int _maxYear = 2100;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;

    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _minYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _updateDate() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    if (_selectedDay > daysInMonth) {
      _selectedDay = daysInMonth;
      if (_dayController.hasClients) {
        _dayController.jumpToItem(_selectedDay - 1);
      }
    }

    widget.onDateChanged(DateTime(_selectedYear, _selectedMonth, _selectedDay));
    setState(() {}); // UI更新（日の最大値が変わる可能性があるため）
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          // Year
          Expanded(
            child: CupertinoPicker.builder(
              scrollController: _yearController,
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                _selectedYear = _minYear + index;
                _updateDate();
              },
              itemBuilder: (context, index) {
                if (index < 0 || index > (_maxYear - _minYear)) return null;
                return Center(
                  child: Text(
                    '${_minYear + index}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              },
              childCount: _maxYear - _minYear + 1,
            ),
          ),
          // Month
          Expanded(
            child: CupertinoPicker.builder(
              scrollController: _monthController,
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                _selectedMonth = index + 1;
                _updateDate();
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              },
              childCount: 12,
            ),
          ),
          // Day
          Expanded(
            child: CupertinoPicker.builder(
              scrollController: _dayController,
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                _selectedDay = index + 1;
                widget.onDateChanged(
                  DateTime(_selectedYear, _selectedMonth, _selectedDay),
                );
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              },
              childCount: DateTime(_selectedYear, _selectedMonth + 1, 0).day,
            ),
          ),
        ],
      ),
    );
  }
}
