import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recolle/core/constants/field_limits.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/features/account/account_validation.dart';
import 'package:recolle/features/account/providers/auth_service_provider.dart';

/// パスワード再設定用メールの送信依頼。
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!looksLikeEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('有効なメールアドレスを入力してください。')),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).requestPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'リセット用のメールを送信しました。メール内のリンクからパスワードを変更してください。',
          ),
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/account');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toUserFriendlyMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワードを再設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '登録したメールアドレスに、パスワード再設定用のリンクをお送りします。',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withAlpha(220),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            maxLength: AccountFieldLimits.email,
            decoration: const InputDecoration(
              labelText: 'メールアドレス',
              helperText: '@ とドメイン（.com など）を含む形式で入力',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('送信する'),
          ),
        ],
      ),
    );
  }
}
