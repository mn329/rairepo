import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:recolle/core/constants/field_limits.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/features/account/account_validation.dart';
import 'package:recolle/features/account/providers/auth_service_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// メール内リンクでリカバリーに入ったあと、新しいパスワードを確定する画面。
class ResetPasswordScreen extends HookConsumerWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController = useTextEditingController();
    final confirmController = useTextEditingController();
    final busy = useState(false);

    final authService = ref.read(authServiceProvider);
    final email = authService.currentEmail ?? '';

    Future<void> submit() async {
      final p = passwordController.text;
      if (!looksLikePassword(p)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードは6文字以上で入力してください。')),
        );
        return;
      }
      if (p != confirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワード（確認）が一致しません。')),
        );
        return;
      }
      if (busy.value) return;
      busy.value = true;
      try {
        await authService.updatePassword(p);
        if (!context.mounted) return;
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードを更新しました。')),
        );
        context.go('/');
      } on AuthException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(toUserFriendlyMessage(e))),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(toUserFriendlyMessage(e))),
        );
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('新しいパスワードを設定')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'メール内のリンクから開いた状態で、新しいパスワードを入力してください。',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withAlpha(220),
              height: 1.45,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              email,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: passwordController,
            obscureText: true,
            maxLength: AccountFieldLimits.password,
            decoration: const InputDecoration(
              labelText: '新しいパスワード',
              helperText: '6文字以上',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmController,
            obscureText: true,
            maxLength: AccountFieldLimits.password,
            decoration: const InputDecoration(
              labelText: '新しいパスワード（確認）',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy.value ? null : submit,
            child: busy.value
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('パスワードを更新'),
          ),
        ],
      ),
    );
  }
}
