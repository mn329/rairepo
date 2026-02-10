import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  String? get currentEmail => _client.auth.currentUser?.email;

  Future<void> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    await _client.auth.updateUser(
      UserAttributes(data: <String, dynamic>{'display_name': trimmed}),
    );
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email.trim(), password: password);
  }

  /// 匿名ログインします（開発中の動作確認などに利用）。
  ///
  /// Supabase 側で Anonymous Sign-ins が有効である必要があります。
  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
  }

  /// パスワードリセットメールを送信します。
  ///
  /// 注意: Supabase 側で Email Provider が有効でないと失敗します。
  Future<void> requestPasswordResetEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// 確認メール（サインアップ/メール変更時など）の再送。
  Future<void> resendSignupConfirmationEmail({required String email}) async {
    await _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  /// メールアドレスを変更します（通常は確認メールが送られます）。
  Future<void> updateEmail(String email) async {
    await _client.auth.updateUser(UserAttributes(email: email.trim()));
  }

  /// パスワードを変更します。
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  /// セッション更新（期限切れ対策）。
  Future<void> refreshSession() async {
    await _client.auth.refreshSession();
  }

  /// 匿名ユーザーを Email/Password ユーザーへ昇格します。
  ///
  /// Supabase 側で Anonymous Sign-ins と Email Provider が有効である必要があります。
  Future<void> upgradeAnonymousToPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('ユーザーが存在しません。');
    }
    if (!user.isAnonymous) {
      throw const AuthException('匿名ユーザーではありません。');
    }

    final data = <String, dynamic>{};
    final trimmedName = displayName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      data['display_name'] = trimmedName;
    }

    await _client.auth.updateUser(
      UserAttributes(
        email: email.trim(),
        password: password,
        data: data.isEmpty ? null : data,
      ),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 現在のセッションを破棄して、匿名セッションに戻します。
  /// このアプリは「ユーザーID単位」でrecordsを見ているため、IDが変わる点に注意。
  Future<void> resetToAnonymous() async {
    await _client.auth.signOut();
    await _client.auth.signInAnonymously();
  }
}
