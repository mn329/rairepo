import 'package:flutter/foundation.dart';

/// メール再設定直後、JWT の `amr` が [recovery] と取れない場合でも
/// 再設定画面へ誘導する。Auth の [passwordRecovery] イベントで有効化する。
///
/// パスワード更新・サインアウトで [clear] する。
class PasswordRecoveryNavFlag extends ChangeNotifier {
  PasswordRecoveryNavFlag._();
  static final instance = PasswordRecoveryNavFlag._();

  bool _active = false;

  bool get isActive => _active;

  void setActiveFromAuthEvent() {
    if (_active) return;
    _active = true;
    notifyListeners();
  }

  void clear() {
    if (!_active) return;
    _active = false;
    notifyListeners();
  }
}
