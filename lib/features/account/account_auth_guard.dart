import 'package:flutter/material.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/features/account/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef SetBusy = void Function(bool value);

Future<void> runAccountAuthGuarded({
  required BuildContext context,
  required bool Function() isBusy,
  required SetBusy setBusy,
  required TextEditingController emailController,
  required AuthService authService,
  required Future<void> Function() fn,
}) async {
  if (isBusy()) return;
  setBusy(true);
  try {
    await fn();
  } on AuthException catch (e) {
    debugPrint(
      'AuthException code=${e.code} statusCode=${e.statusCode} message=${e.message}',
    );
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (e.code == 'email_not_confirmed') {
      final email = emailController.text.trim();
      messenger.showSnackBar(
        SnackBar(
          content: Text(toUserFriendlyMessage(e)),
          action: SnackBarAction(
            label: '再送する',
            onPressed: () async {
              try {
                await authService.resendSignupConfirmationEmail(email: email);
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('確認メールを再送しました')),
                  );
                }
              } catch (err) {
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(toUserFriendlyMessage(err))),
                  );
                }
              }
            },
          ),
        ),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(toUserFriendlyMessage(e))));
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(toUserFriendlyMessage(e))));
  } finally {
    if (context.mounted) {
      setBusy(false);
    }
  }
}
