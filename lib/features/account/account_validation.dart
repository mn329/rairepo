/// メール・パスワードの入力が「それっぽいか」の最小チェック。
bool looksLikeEmail(String s) {
  final t = s.trim();
  return t.isNotEmpty && t.contains('@') && t.contains('.');
}

/// Supabase 側の制約はプロジェクト設定次第なので、ここは最小限のチェックに留める。
bool looksLikePassword(String s) {
  return s.isNotEmpty && s.length >= 6;
}
