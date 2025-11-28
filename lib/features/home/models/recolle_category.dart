import 'package:flutter/material.dart';

enum RecolleCategory {
  live('ライブ', Icons.music_note),
  book('本', Icons.book),
  movie('映画', Icons.movie),
  other('その他', Icons.category);

  final String label;
  final IconData icon;

  const RecolleCategory(this.label, this.icon);
}

