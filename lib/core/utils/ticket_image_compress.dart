import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:recolle/core/constants/ticket_image_settings.dart';

/// ギャラリー画像をチケット表示・アップロード向けに JPEG で軽量化する。
///
/// 失敗時は [source] をそのまま返す。
Future<File> compressTicketImageForUpload(File source) async {
  try {
    final tmp = await getTemporaryDirectory();
    final outPath = p.join(
      tmp.path,
      'ticket_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      outPath,
      quality: TicketImageSettings.compressQuality,
      minWidth: TicketImageSettings.compressMaxEdge,
      minHeight: TicketImageSettings.compressMaxEdge,
      format: CompressFormat.jpeg,
    );
    if (result == null) return source;
    return File(result.path);
  } catch (e, st) {
    debugPrint('compressTicketImageForUpload: $e\n$st');
    return source;
  }
}
