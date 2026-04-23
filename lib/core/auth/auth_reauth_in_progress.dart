import 'package:flutter/foundation.dart';

/// ログアウト直後の匿名再ログインのように、一時的に [session] が [null] になる操作の最中は true。
/// この間 [GoRouter] では [session] なしの強制遷移をしない（チラつき防止）。
class AuthReauthInProgress extends ChangeNotifier {
  AuthReauthInProgress._();
  static final AuthReauthInProgress instance = AuthReauthInProgress._();

  int _nesting = 0;

  bool get isInProgress => _nesting > 0;

  void begin() {
    _nesting++;
    if (_nesting == 1) {
      notifyListeners();
    }
  }

  void end() {
    if (_nesting == 0) {
      return;
    }
    _nesting--;
    if (_nesting == 0) {
      notifyListeners();
    }
  }
}
