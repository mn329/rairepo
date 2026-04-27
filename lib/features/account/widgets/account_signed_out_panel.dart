import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recolle/core/constants/field_limits.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/features/account/account_signup_confirmation_dialog.dart';
import 'package:recolle/features/account/account_validation.dart';
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
    required this.isAnonymous,
    required this.showConnectionRecovery,
    required this.onToggleSignupMode,
    required this.runGuarded,
    required this.authService,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool isBusy;
  final bool isSignup;

  /// 匿名セッションかどうか（表示の一部・バリデーションで利用）。
  final bool isAnonymous;

  /// セッションが取れていない場合の「匿名で再接続」用。
  final bool showConnectionRecovery;
  final VoidCallback onToggleSignupMode;
  final Future<void> Function(Future<void> Function() fn) runGuarded;
  final AuthService authService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isSignup ? '新規登録' : 'ログイン';
    return AccountExpandableSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showConnectionRecovery) ...[
            Text(
              'Supabase への接続に失敗したか、前回のセッションが切れています。',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withAlpha(200),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: isBusy
                  ? null
                  : () {
                      runGuarded(() async {
                        await authService.signInAnonymously();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('接続しました。思い出の記録を始められます。'),
                          ),
                        );
                      });
                    },
              child: const Text('匿名IDで接続'),
            ),
            const SizedBox(height: 16),
            Text(
              'メール登録（任意）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gold.withAlpha(220),
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                    : () {
                        final e = emailController.text.trim();
                        final q = e.isEmpty
                            ? ''
                            : '?email=${Uri.encodeComponent(e)}';
                        context.push('/forgot-password$q');
                      },
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
                      final user = ref.read(authUserProvider).asData?.value;
                      if (user != null &&
                          !user.isAnonymous &&
                          user.emailConfirmedAt != null) {
                        throw const AuthException('既にログイン（登録）済みのアカウントです。');
                      }
                      final e = emailController.text.trim();
                      if (!looksLikeEmail(e)) {
                        throw const AuthException('メールアドレスを入力してください。');
                      }
                      final password = passwordController.text;
                      if (!looksLikePassword(password)) {
                        throw const AuthException('パスワードは6文字以上で入力してください。');
                      }
                      if (isSignup) {
                        if (password != passwordConfirmController.text) {
                          throw const AuthException('パスワード（確認）が一致しません。');
                        }
                        await authService.signUpWithEmailPassword(
                          email: e,
                          password: password,
                        );
                        if (!context.mounted) return;
                        FocusScope.of(context).unfocus();
                        final needsConfirm = authService.currentSession == null;
                        if (needsConfirm) {
                          await showSignupEmailConfirmationDialog(
                            context: context,
                            authService: authService,
                            email: e,
                          );
                        } else if (authService.currentUser?.emailConfirmedAt ==
                            null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('メールを送信しました。メール内のリンクから認証が必要です。'),
                            ),
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
          if (isSignup && !isAnonymous) ...[
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
