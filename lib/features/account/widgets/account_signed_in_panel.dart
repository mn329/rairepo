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
    return AccountExpandableSection(
      title: 'ログアウト',
      child: FilledButton.tonal(
        onPressed: isBusy
            ? null
            : () {
                runGuarded(() async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'ログアウトしますか？',
                    message: 'この端末からログアウトします。',
                    okText: 'ログアウト',
                  );
                  if (!ok) return;
                  await authService.signOut();
                });
              },
        child: const Text('ログアウト'),
      ),
    );
  }
}
