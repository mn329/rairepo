import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// メール内の認証コールバック URL か（`auth_redirect.dart` と一致するスキーム）。
bool isEmailAuthCallbackDeepLink(Uri? uri) {
  if (uri == null) return false;
  if (uri.scheme != 'io.supabase.recolle' || uri.host != 'login-callback') {
    return false;
  }
  final f = uri.fragment;
  if (f.contains('error_description')) return false;
  return f.contains('access_token') ||
      f.contains('code') ||
      uri.queryParameters.containsKey('code');
}

/// `#code=...` は [Uri.queryParameters] に載らない。PKCE の `getSessionFromUrl` が読めるよう query に繋ぐ。
Uri normalizeEmailAuthDeepLink(Uri uri) {
  if (uri.fragment.isEmpty) return uri;
  final fragParams = Uri.splitQueryString(uri.fragment);
  if (fragParams.isEmpty) return uri;
  final merged = Map<String, String>.from(uri.queryParameters);
  merged.addAll(fragParams);
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    queryParameters: merged.isEmpty ? null : merged,
  );
}

/// メールリンクからセッションを確立する。冷起動・バックグラウンド復帰の両方で呼べる。
/// 二重呼び出しで code が無効な場合は無視する。
Future<void> exchangeSessionFromEmailAuthDeepLink(Uri uri) async {
  final normalized = normalizeEmailAuthDeepLink(uri);
  try {
    await Supabase.instance.client.auth.getSessionFromUrl(normalized);
  } catch (e, st) {
    assert(() {
      debugPrint(
        'exchangeSessionFromEmailAuthDeepLink (二重や期限切れでは無視可): $e\n$st',
      );
      return true;
    }());
  }
}
