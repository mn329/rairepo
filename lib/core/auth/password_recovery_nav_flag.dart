import 'package:flutter/foundation.dart';

/// メール再設定直後、JWT の `amr` が [recovery] と取れない場合でも
/// 再設定画面へ誘導する。Auth の [passwordRecovery] イベントで有効化する。
///
/// [markPostRecoveryPasswordUpdateSuccess] は、リカバリーフロー内で
/// パスワード更新直後 — JWT 上の `amr` が消えるまでの一瞬
/// [sessionRequiresNewPasswordAfterRecovery] が偽に見えず [GoRouter] が
/// ホームへ戻る遷移を奪うのを防ぐ。
///
/// サインアウトで [clear] する。
class PasswordRecoveryNavFlag extends ChangeNotifier {
  PasswordRecoveryNavFlag._();
  static final instance = PasswordRecoveryNavFlag._();

  bool _active = false;

  /// 再設定成功直後: [amr] が古いトークンを指している間、リダイレクトから除外する
  bool _bypassRecoverySessionGuard = false;

  bool get isActive => _active;

  /// [sessionRequiresNewPasswordAfterRecovery] 用: 更新完了後は一時的に偽扱いにする
  bool get bypassesRecoverySessionGuard => _bypassRecoverySessionGuard;

  void setActiveFromAuthEvent() {
    _bypassRecoverySessionGuard = false;
    if (_active) return;
    _active = true;
    notifyListeners();
  }

  void markPostRecoveryPasswordUpdateSuccess() {
    _active = false;
    if (!_bypassRecoverySessionGuard) {
      _bypassRecoverySessionGuard = true;
    }
    notifyListeners();
  }

  void clear() {
    if (!_active && !_bypassRecoverySessionGuard) {
      return;
    }
    _active = false;
    _bypassRecoverySessionGuard = false;
    notifyListeners();
  }
}
