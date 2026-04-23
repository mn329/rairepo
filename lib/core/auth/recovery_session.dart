import 'package:jwt_decode/jwt_decode.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// アクセストークンの `amr` がパスワードリカバリー由来かどうか（メールリンク後の一時セッション）。
bool accessTokenRequiresPasswordRecovery(String accessToken) {
  try {
    final payload = Jwt.parseJwt(accessToken);
    final amr = payload['amr'];
    if (amr is List) {
      for (final e in amr) {
        if (e == 'recovery') return true;
        if (e is Map && e['method'] == 'recovery') return true;
      }
    }
  } catch (_) {}
  return false;
}

/// メールのパスワード再設定リンク後、新パスワード入力が必要な状態か。
bool sessionRequiresNewPasswordAfterRecovery(Session? session) {
  if (session == null || session.user.isAnonymous) return false;
  return accessTokenRequiresPasswordRecovery(session.accessToken);
}
