import 'package:flutter/material.dart';
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
