import 'package:flutter/foundation.dart';

/// メール内リンク（サインアップ・パスワード再設定など）が最終的に戻るURL。
/// Supabase ダッシュボードの Authentication → URL Configuration → Redirect URLs に
/// 同じ文字列（末尾スラッシュなし）を必ず登録する。
const kSupabaseAppEmailRedirect = 'io.supabase.recolle://login-callback';

String supabaseEmailRedirectToForPlatform() =>
    kIsWeb ? Uri.base.origin : kSupabaseAppEmailRedirect;
