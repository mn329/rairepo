// Supabase の Flutter 用パッケージを読み込む（認証例外などの型を使うため）
import 'package:supabase_flutter/supabase_flutter.dart';

/// アプリ内でユーザーに表示するエラーメッセージを日本語で返します。
// 引数 error を受け取り、ユーザー向けの日本語メッセージ（文字列）を返す関数を定義する
String toUserFriendlyMessage(dynamic error) {
  // error が null かどうかを判定する
  if (error == null) {
    // null のときは、汎用メッセージを返して関数を終える
    return '問題が発生しました。しばらくして再度お試しください。';
  }

  // error が Supabase の認証例外（AuthException）型かどうかを判定する
  if (error is AuthException) {
    final fromCode = _authMessageFromCode(error.code);
    if (fromCode != null) {
      return fromCode;
    }
    // 認証例外のときは、内部関数を呼んでその戻り値を返す
    return _authMessage(error.message);
  }

  // エラーを文字列に変換し、小文字にしたものを入れるための箱を作る（比較しやすくするため）
  final raw = error.toString().toLowerCase();

  // ネットワーク・接続
  // raw にソケット例外や接続失敗を示す文字列が含まれるか判定する
  if (raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('connection refused') ||
      raw.contains('network is unreachable')) {
    // 含まれるときは、ネットワーク用のメッセージを返す
    return 'サーバーに接続できませんでした。ネットワーク設定と接続を確認してください。';
  }

  // ストレージ（バケット未作成など）
  // raw にストレージ関連のエラーを示す文字列が含まれるか判定する
  if (raw.contains('storageexception') || raw.contains('bucket not found')) {
    // 含まれるときは、ストレージ用のメッセージを返す
    return '画像の保存に失敗しました。ストレージの設定（バケット名: ticket-images）を確認してください。';
  }

  // データベース・権限
  // raw に DB や権限関連のエラーを示す文字列が含まれるか判定する
  if (raw.contains('postgrest') ||
      raw.contains('row level security') ||
      raw.contains('permission denied')) {
    // 含まれるときは、データ処理失敗用のメッセージを返す
    return 'データの処理に失敗しました。しばらくして再度お試しください。';
  }

  // タイムアウト
  // raw にタイムアウトを示す文字列が含まれるか判定する
  if (raw.contains('timeout') || raw.contains('timed out')) {
    // 含まれるときは、タイムアウト用のメッセージを返す
    return '通信がタイムアウトしました。接続を確認して再度お試しください。';
  }

  // Supabase Edge Functions の例外
  if (error is FunctionException) {
    return '通信エラーが発生しました (${error.status})。しばらく待ってから再度お試しください。';
  }

  // どのパターンにも当てはまらないときは、汎用メッセージを返す
  return '問題が発生しました。しばらくして再度お試しください。';
}

/// GoTrue が返す [AuthException.code] を優先して日本語にします。
/// https://github.com/supabase/auth/blob/master/internal/api/errorcodes.go
String? _authMessageFromCode(String? code) {
  if (code == null) return null;
  switch (code) {
    case 'over_request_rate_limit':
      return 'アクセスが集中しています。しばらく待ってから再度お試しください。';
    case 'user_already_exists':
    case 'email_exists':
      return 'このメールアドレスは既にログイン（登録）済みのアカウントです。';
    case 'weak_password':
      return 'パスワードが要件を満たしていません。長めのパスワードを試してください。';
    case 'same_password':
      return '新しいパスワードは、現在のパスワードと異なるものを設定してください。';
    case 'email_not_confirmed':
      return 'メールアドレスがまだ確認されていません。確認メールのリンクを開いてください。';
    case 'signup_disabled':
      return '新規登録が無効になっています。Supabase の Authentication → Providers を確認してください。';
    case 'email_provider_disabled':
      return 'メールでのサインアップが無効です。Supabase の Authentication → Providers で Email を有効にしてください。';
    case 'hook_timeout':
    case 'hook_timeout_after_retry':
    case 'hook_payload_over_size_limit':
      return '登録処理でサーバー側のフックが失敗しました。Supabase の Auth Hooks / ログを確認してください。';
    default:
      return null;
  }
}

/// Supabase Auth の英語メッセージを日本語に変換します。
// 引数 message（英語のエラーメッセージ）を受け取り、日本語の文字列を返す関数を定義する（ファイル内だけで使うため _ で始まる）
String _authMessage(String message) {
  // メッセージを小文字にしたものを入れるための箱を作る（含むかどうかの判定をしやすくするため）
  final m = message.toLowerCase();
  // ログイン情報不正を示す文字列が含まれるか判定する
  if (m.contains('invalid login credentials') ||
      m.contains('invalid_credentials')) {
    // 含まれるときは、対応する日本語メッセージを返す
    return 'メールアドレスまたはパスワードが正しくありません。';
  }
  // メール未確認を示す文字列が含まれるか判定する
  if (m.contains('email not confirmed') || m.contains('email_not_confirmed')) {
    return 'メールアドレスがまだ確認されていません。確認メールのリンクを開いてください。';
  }
  // ユーザーが存在しないことを示す文字列が含まれるか判定する
  if (m.contains('user not found')) {
    return 'ユーザーが見つかりません。入力したメールアドレスが正しいか確認してください。';
  }
  // 既に登録済みを示す文字列が含まれるか判定する
  if (m.contains('user already registered') ||
      m.contains('already registered') ||
      m.contains('already exists')) {
    return 'このメールアドレスは既にログイン（登録）済みのアカウントです。';
  }
  // パスワード長不足を示す文字列が含まれるか判定する
  if (m.contains('password should be at least')) {
    return 'パスワードは6文字以上で入力してください。';
  }
  // サインアップ無効を示す文字列が含まれるか判定する
  if (m.contains('signup disabled') || m.contains('sign_up_disabled')) {
    return '新規登録が無効になっています。';
  }
  // 匿名ログイン無効を示す文字列が含まれるか判定する
  if (m.contains('anonymous sign-ins are disabled')) {
    return '匿名ログインは無効になっています。';
  }
  // レート制限（コードが付かない／文言だけの返答のとき）
  if (m.contains('rate limit') ||
      m.contains('too many requests') ||
      m.contains('too_many') ||
      m.contains('email rate limit') ||
      m.contains('over_email_send')) {
    return 'アクセスが集中しているか、短時間に試行しすぎています。しばらく待ってから再度お試しください。';
  }
  // メール形式不正を示す文字列が含まれるか判定する
  if (m.contains('invalid email') ||
      m.contains('invalid format') ||
      m.contains('validate email') ||
      m.contains('valid email')) {
    return '正しいメールアドレスを入力してください。（例: name@example.com）';
  }
  // パスワードリセット系を示す文字列が含まれるか判定する
  if (m.contains('forgot password') || m.contains('reset password')) {
    return 'パスワードリセット用のメールを送信しました。メールをご確認ください。';
  }
  // メールアドレス変更の確認メール送信失敗（Auth API が 500 を返すことがある）
  if (m.contains('error sending email change') ||
      m.contains('sending email change')) {
    return 'メールアドレス変更の確認メールを送れませんでした。Supabase の Authentication → SMTP（Resend 等）のホスト・ポート・認証情報・送信元ドメイン、および Resend のドメイン検証と API キーを確認してください。';
  }
  // 確認メール・SMTP 未設定（新規登録でよく出る）
  // メール送信失敗（SMTP 等）を示す文字列が含まれるか判定する
  if (m.contains('email provider') ||
      m.contains('smtp') ||
      m.contains('mail server') ||
      m.contains('confirm email')) {
    return '確認メールの送信に失敗しています。Supabase の Authentication → Email Templates と SMTP 設定を確認してください。';
  }
  // 新規登録無効
  // 「signup」と「disabled」の両方が含まれるか判定する
  if (m.contains('signup') && m.contains('disabled')) {
    return '新規登録が無効になっています。Supabase の Authentication → Providers → Email で「Enable Sign Up」をオンにしてください。';
  }
  // DB 保存失敗（トリガー・RLS 等）
  if (m.contains('database error') ||
      m.contains('saving new user') ||
      m.contains('error saving user')) {
    return 'ユーザー情報の保存に失敗しました。Supabase の Authentication ログと auth.users まわりのトリガーを確認してください。';
  }
  // 既に日本語のメッセージならそのまま返す
  // ひらがな・カタカナ・漢字などが含まれるか正規表現で判定する（日本語が含まれていれば元の message を返す）
  if (RegExp(r'[\u3000-\u303f\u3040-\u309f\u30a0-\u30ff\uff00-\uffef\u4e00-\u9faf]')
      .hasMatch(message)) {
    return message;
  }
  // どのパターンにも当てはまらない認証エラーのときは、汎用の認証メッセージを返す
  return '認証中に問題が発生しました。入力内容を確認してください。';
}
