import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recolle/core/auth/recovery_session.dart';

String _fakeAccessToken(Map<String, dynamic> payload) {
  final jsonStr = jsonEncode(payload);
  final b64 = base64Url.encode(utf8.encode(jsonStr));
  final normalized = b64.replaceAll('=', '');
  return 'x.$normalized.y';
}

void main() {
  group('accessTokenRequiresPasswordRecovery', () {
    test('true when amr contains recovery map', () {
      final token = _fakeAccessToken({
        'amr': [
          {'method': 'recovery', 'timestamp': 1},
        ],
      });
      expect(accessTokenRequiresPasswordRecovery(token), isTrue);
    });

    test('true when amr contains recovery string', () {
      final token = _fakeAccessToken({'amr': ['recovery']});
      expect(accessTokenRequiresPasswordRecovery(token), isTrue);
    });

    test('false for password method', () {
      final token = _fakeAccessToken({
        'amr': [
          {'method': 'password', 'timestamp': 1},
        ],
      });
      expect(accessTokenRequiresPasswordRecovery(token), isFalse);
    });

    test('false for malformed token', () {
      expect(accessTokenRequiresPasswordRecovery('not-a-jwt'), isFalse);
    });
  });
}
