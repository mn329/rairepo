import 'package:jwt_decode/jwt_decode.dart';
import 'package:recolle/core/auth/password_recovery_nav_flag.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `amr` からリカバリーセッションか。文字列 / オブジェクト / method 名の揺れに対応。
bool amrListIndicatesRecovery(Object? amr) {
  if (amr is! List) return false;
  for (final e in amr) {
    if (e == 'recovery') return true;
    if (e is Map) {
      final m = e['method'];
      if (m == 'recovery') return true;
    }
  }
  return false;
}

/// アクセストークンの `amr` がパスワードリカバリー由来か（メールリンク後の一時セッション）。
bool accessTokenRequiresPasswordRecovery(String accessToken) {
  try {
    final payload = Jwt.parseJwt(accessToken);
    if (amrListIndicatesRecovery(payload['amr'])) return true;
  } catch (_) {}
  return false;
}

/// メールのパスワード再設定リンク後、新パスワード入力が必要な状態か。
///
/// JWT の [amr] だけに依存すると、Supabase/GoTrue の表記差で取り逃すことがある。
/// そのため [AuthChangeEvent.passwordRecovery] 時に立てるフラグを OR する。
bool sessionRequiresNewPasswordAfterRecovery(Session? session) {
  if (session == null || session.user.isAnonymous) return false;
  if (PasswordRecoveryNavFlag.instance.bypassesRecoverySessionGuard) {
    return false;
  }
  if (PasswordRecoveryNavFlag.instance.isActive) return true;
  return accessTokenRequiresPasswordRecovery(session.accessToken);
}
