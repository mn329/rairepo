import 'package:flutter/material.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/features/account/services/auth_service.dart';

/// サインアップ後、メール確認が必要な場合に表示するダイアログ。
Future<void> showSignupEmailConfirmationDialog({
  required BuildContext context,
  required AuthService authService,
  required String email,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('確認メールを送信しました'),
      content: SingleChildScrollView(
        child: Text(
          '「$email」宛に確認メールを送りました。\n\n'
          'メール内のリンクを開いて認証したあと、'
          '「ログインはこちら」から同じメールとパスワードでログインしてください。\n\n'
          '※ 認証が完了するまでホーム画面には進めません。',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await authService.resendSignupConfirmationEmail(email: email);
              if (!ctx.mounted) {
                return;
              }
              Navigator.of(ctx).pop();
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('確認メールを再送しました')),
              );
            } catch (err) {
              if (!ctx.mounted) {
                return;
              }
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(toUserFriendlyMessage(err))),
              );
            }
          },
          child: const Text('確認メールを再送'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
