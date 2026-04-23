import 'package:flutter/foundation.dart';
import 'package:recolle/core/auth/auth_reauth_in_progress.dart';
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
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.recolle://login-callback/',
    );
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
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.recolle://login-callback/',
    );
  }

  /// 確認メール（サインアップ/メール変更時など）の再送。
  Future<void> resendSignupConfirmationEmail({required String email}) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.recolle://login-callback/',
    );
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
      throw const AuthException('既にログイン（登録）済みのアカウントです。');
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
    AuthReauthInProgress.instance.begin();
    try {
      await _client.auth.signOut();
      await _client.auth.signInAnonymously();
    } finally {
      AuthReauthInProgress.instance.end();
    }
  }

  /// メール登録済みユーザーをアプリ上から完全削除（Edge Function `delete-account`）。
  /// 成功後、匿名利用に戻る。
  Future<void> deleteRegisteredAccount() async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('セッションがありません。');
    }
    if (user.isAnonymous) {
      throw const AuthException('メールで登録したアカウントのみ削除できます。');
    }

    try {
      await _client.functions.invoke('delete-account');
    } on FunctionException catch (e) {
      String msg;
      if (e.details is Map) {
        final m = e.details as Map<dynamic, dynamic>;
        final err = m['error'] ?? m['message'];
        msg = err == null
            ? 'アカウントの削除に失敗しました。'
            : err.toString();
      } else {
        msg = e.details?.toString() ?? 'アカウントの削除に失敗しました。';
      }
      throw AuthException(msg);
    }

    AuthReauthInProgress.instance.begin();
    try {
      try {
        await _client.auth.signOut();
      } catch (_) {}
      try {
        await _client.auth.signInAnonymously();
      } catch (e) {
        throw AuthException('削除後の再接続に失敗しました: $e');
      }
    } finally {
      AuthReauthInProgress.instance.end();
    }
  }
}
