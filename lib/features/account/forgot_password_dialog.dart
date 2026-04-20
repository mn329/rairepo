import 'package:flutter/material.dart';
import 'package:recolle/core/constants/field_limits.dart';
import 'package:recolle/features/account/services/auth_service.dart';

void showForgotPasswordDialog({
  required BuildContext context,
  required AuthService authService,
  required String initialEmail,
  required Future<void> Function(Future<void> Function() fn) runGuarded,
}) {
  final controller = TextEditingController(text: initialEmail);
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('パスワードをリセット'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        maxLength: AccountFieldLimits.email,
        decoration: const InputDecoration(labelText: '登録したメールアドレス'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () async {
            final email = controller.text.trim();
            if (email.isEmpty ||
                !email.contains('@') ||
                !email.contains('.')) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('有効なメールアドレスを入力してください。')),
              );
              return;
            }
            Navigator.of(ctx).pop();
            await runGuarded(() async {
              await authService.requestPasswordResetEmail(email: email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'リセット用のメールを送信しました。メール内のリンクからパスワードを変更してください。',
                    ),
                  ),
                );
              }
            });
          },
          child: const Text('送信'),
        ),
      ],
    ),
  );
}
