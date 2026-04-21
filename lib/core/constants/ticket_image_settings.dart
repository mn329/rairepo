/// チケット画像の選択時リサイズ・JPEG 再圧縮の共通設定。
abstract final class TicketImageSettings {
  TicketImageSettings._();

  /// [ImagePicker.pickImage] の長辺上限（px）。
  static const double maxPickDimension = 2048;

  /// ギャラリー選択時の JPEG 品質（0–100）。
  static const int pickImageQuality = 82;

  /// [FlutterImageCompress] の JPEG 品質（0–100）。
  static const int compressQuality = 78;

  /// 再圧縮時の長辺・短辺の上限（px）。縦横どちらが長くてもこのボックスに収まるよう縮小。
  static const int compressMaxEdge = 1920;
}
