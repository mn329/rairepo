import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recolle/core/constants/field_limits.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/features/account/account_signup_confirmation_dialog.dart';
import 'package:recolle/features/account/account_validation.dart';
import 'package:recolle/features/account/forgot_password_dialog.dart';
import 'package:recolle/features/account/providers/auth_providers.dart';
import 'package:recolle/features/account/widgets/account_expandable_section.dart';
import 'package:recolle/features/account/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSignedOutPanel extends ConsumerWidget {
  const AccountSignedOutPanel({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.isBusy,
    required this.isSignup,
    required this.onToggleSignupMode,
    required this.runGuarded,
    required this.authService,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool isBusy;
  final bool isSignup;
  final VoidCallback onToggleSignupMode;
  final Future<void> Function(Future<void> Function() fn) runGuarded;
  final AuthService authService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AccountExpandableSection(
      title: isSignup ? '新規登録' : 'ログイン',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            maxLength: AccountFieldLimits.email,
            decoration: const InputDecoration(
              labelText: 'メールアドレス',
              helperText: '@ とドメイン（.com など）を含む形式で入力',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            maxLength: AccountFieldLimits.password,
            decoration: InputDecoration(
              labelText: 'パスワード',
              hintText: isSignup ? '6文字以上' : null,
              helperText: '6文字以上',
            ),
          ),
          if (isSignup) ...[
            const SizedBox(height: 12),
            TextField(
              controller: passwordConfirmController,
              obscureText: true,
              maxLength: AccountFieldLimits.password,
              decoration: const InputDecoration(
                labelText: 'パスワード（確認）',
                helperText: '上記と同じパスワードを再入力',
              ),
            ),
          ],
          if (!isSignup) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy
                    ? null
                    : () => showForgotPasswordDialog(
                          context: context,
                          authService: authService,
                          initialEmail: emailController.text,
                          runGuarded: runGuarded,
                        ),
                child: Text(
                  'パスワードを忘れた場合',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gold.withAlpha(200),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isBusy
                ? null
                : () {
                    runGuarded(() async {
                      final user =
                          ref.read(authUserProvider).asData?.value;
                      if (user != null && !user.isAnonymous) {
                        throw const AuthException(
                          '既にログイン（登録）済みのアカウントです。',
                        );
                      }
                      final e = emailController.text.trim();
                      if (!looksLikeEmail(e)) {
                        throw const AuthException(
                          'メールアドレスを入力してください。',
                        );
                      }
                      final password = passwordController.text;
                      if (!looksLikePassword(password)) {
                        throw const AuthException(
                          'パスワードは6文字以上で入力してください。',
                        );
                      }
                      if (isSignup) {
                        if (password != passwordConfirmController.text) {
                          throw const AuthException(
                            'パスワード（確認）が一致しません。',
                          );
                        }
                        await authService.signUpWithPassword(
                          email: e,
                          password: password,
                        );
                        if (!context.mounted) return;
                        FocusScope.of(context).unfocus();
                        final needsConfirm =
                            authService.currentSession == null;
                        if (needsConfirm) {
                          await showSignupEmailConfirmationDialog(
                            context: context,
                            authService: authService,
                            email: e,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('登録しました')),
                          );
                        }
                      } else {
                        await authService.signInWithPassword(
                          email: e,
                          password: password,
                        );
                        if (!context.mounted) return;
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ログインしました')),
                        );
                      }
                    });
                  },
            child: Text(isSignup ? '登録する' : 'ログインする'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: isBusy
                ? null
                : () {
                    onToggleSignupMode();
                  },
            child: Text(isSignup ? 'ログインはこちら' : '新規登録はこちら'),
          ),
          if (isSignup) ...[
            const SizedBox(height: 12),
            Text(
              '※ 確認メールが有効な場合、登録後にメール内のリンクから認証が必要です。',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withAlpha(180),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
