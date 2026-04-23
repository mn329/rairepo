import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/core/widgets/confirm_dialog.dart';
import 'package:recolle/features/account/widgets/account_expandable_section.dart';
import 'package:recolle/features/account/services/auth_service.dart';

class AccountSignedInPanel extends StatelessWidget {
  const AccountSignedInPanel({
    super.key,
    required this.isBusy,
    required this.runGuarded,
    required this.authService,
  });

  final bool isBusy;
  final Future<void> Function(Future<void> Function() fn) runGuarded;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountExpandableSection(
          title: 'パスワードの再設定',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '登録メール宛に再設定用のリンクを送ります。メール内のリンクから新しいパスワードを設定してください。',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary.withAlpha(200),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isBusy
                    ? null
                    : () {
                        final email = authService.currentEmail?.trim();
                        if (email == null || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('メールアドレスが取得できません。'),
                            ),
                          );
                          return;
                        }
                        final q =
                            '?email=${Uri.encodeComponent(email)}';
                        context.push('/forgot-password$q');
                      },
                child: const Text('メールでパスワードを再設定'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AccountExpandableSection(
          title: 'ログアウト',
          child: FilledButton.tonal(
            onPressed: isBusy
                ? null
                : () {
                    runGuarded(() async {
                      // await 後はこのパネルはツリーから外れ context が unmount しうる。
                      // Messenger は先に取っておけば表示できる。
                      final messenger = ScaffoldMessenger.of(context);
                      await authService.resetToAnonymous();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('ログアウトしました。')),
                      );
                    });
                  },
            child: const Text('ログアウト'),
          ),
        ),
        const SizedBox(height: 16),
        AccountExpandableSection(
          title: 'アカウントを削除',
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(38),
            ),
            onPressed: isBusy
                ? null
                : () {
                    runGuarded(() async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await showConfirmDialog(
                        context,
                        title: '本当に削除しますか？',
                        message:
                            '思い出データと登録アカウントを完全に消去します。再度メール登録をしても同じ内容は戻りません。',
                        okText: '完全に削除',
                        cancelText: 'キャンセル',
                      );
                      if (!ok) return;
                      await authService.deleteRegisteredAccount();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('アカウントとデータを削除しました')),
                      );
                    });
                  },
            child: const Text('アカウントを完全に削除'),
          ),
        ),
      ],
    );
  }
}
