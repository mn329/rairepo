import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:recolle/core/constants/field_limits.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/features/account/providers/auth_providers.dart';
import 'package:recolle/features/account/providers/auth_service_provider.dart';
import 'package:recolle/features/account/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends HookConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authUserProvider);
    final authService = ref.read(authServiceProvider);

    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final passwordConfirmController = useTextEditingController();

    final isBusy = useState(false);
    final isSignup = useState(false);

    final isMounted = useIsMounted();

    bool looksLikeEmail(String s) {
      final t = s.trim();
      return t.isNotEmpty && t.contains('@') && t.contains('.');
    }

    bool looksLikePassword(String s) {
      // Supabase 側の制約はプロジェクト設定次第なので、ここは最小限のチェックに留める
      return s.isNotEmpty && s.length >= 6;
    }

    Future<bool> confirm({
      required String title,
      required String message,
      String okText = 'OK',
      String cancelText = 'キャンセル',
    }) async {
      final res = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(okText),
            ),
          ],
        ),
      );
      return res ?? false;
    }

    Future<void> runGuarded(Future<void> Function() fn) async {
      if (isBusy.value) return;
      isBusy.value = true;
      try {
        await fn();
      } on AuthException catch (e) {
        debugPrint(
          'AuthException code=${e.code} statusCode=${e.statusCode} message=${e.message}',
        );
        if (isMounted()) {
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
                      await authService.resendSignupConfirmationEmail(
                        email: email,
                      );
                      if (isMounted()) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('確認メールを再送しました')),
                        );
                      }
                    } catch (err) {
                      if (isMounted()) {
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
            messenger.showSnackBar(
              SnackBar(content: Text(toUserFriendlyMessage(e))),
            );
          }
        }
      } catch (e) {
        if (isMounted()) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(toUserFriendlyMessage(e))));
        }
      } finally {
        if (isMounted()) {
          isBusy.value = false;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('アカウント')),
      body: authUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              toUserFriendlyMessage(e),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (user) {
          final email = user?.email;
          final isAnonymous = user?.isAnonymous ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileCard(
                title: user == null
                    ? '未ログイン'
                    : (email != null && email.isNotEmpty
                          ? email
                          : (isAnonymous ? '匿名ユーザー' : 'アカウント')),
                subtitle: user == null
                    ? 'ログインして利用を開始'
                    : (isAnonymous ? '匿名でログイン中' : 'ログイン中'),
              ),
              const SizedBox(height: 16),
              if (user == null)
                _ExpandableSection(
                  title: isSignup.value ? '新規登録' : 'ログイン',
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
                          hintText: isSignup.value ? '6文字以上' : null,
                          helperText: '6文字以上',
                        ),
                      ),
                      if (isSignup.value) ...[
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
                      if (!isSignup.value) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isBusy.value
                                ? null
                                : () => _showForgotPasswordDialog(
                                    context,
                                    authService,
                                    emailController.text,
                                    runGuarded,
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
                        onPressed: isBusy.value
                            ? null
                            : () {
                                runGuarded(() async {
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
                                  if (isSignup.value) {
                                    if (password !=
                                        passwordConfirmController.text) {
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
                                      await showDialog<void>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('確認メールを送信しました'),
                                          content: SingleChildScrollView(
                                            child: Text(
                                              '「$e」宛に確認メールを送りました。\n\n'
                                              'メール内のリンクを開いて認証したあと、'
                                              '「ログインはこちら」から同じメールとパスワードでログインしてください。\n\n'
                                              '※ 認証が完了するまでホーム画面には進めません。',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                try {
                                                  await authService
                                                      .resendSignupConfirmationEmail(
                                                        email: e,
                                                      );
                                                  if (!ctx.mounted) {
                                                    return;
                                                  }
                                                  Navigator.of(ctx).pop();
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        '確認メールを再送しました',
                                                      ),
                                                    ),
                                                  );
                                                } catch (err) {
                                                  if (!ctx.mounted) {
                                                    return;
                                                  }
                                                  ScaffoldMessenger.of(
                                                    ctx,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        toUserFriendlyMessage(
                                                          err,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('確認メールを再送'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('閉じる'),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                        child: Text(isSignup.value ? '登録する' : 'ログインする'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: isBusy.value
                            ? null
                            : () {
                                isSignup.value = !isSignup.value;
                                if (isSignup.value) {
                                  passwordConfirmController.clear();
                                }
                              },
                        child: Text(isSignup.value ? 'ログインはこちら' : '新規登録はこちら'),
                      ),
                      if (isSignup.value) ...[
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
                )
              else
                _ExpandableSection(
                  title: 'ログアウト',
                  child: FilledButton.tonal(
                    onPressed: isBusy.value
                        ? null
                        : () {
                            runGuarded(() async {
                              final ok = await confirm(
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
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withAlpha(64)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withAlpha(89)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceLight,
            child: Icon(Icons.person, color: AppColors.gold.withAlpha(230)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary.withAlpha(166)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// パスワードリセット用メール送信ダイアログを表示する。
void _showForgotPasswordDialog(
  BuildContext context,
  AuthService authService,
  String initialEmail,
  Future<void> Function(Future<void> Function() fn) runGuarded,
) {
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
            if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
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
                    content: Text('リセット用のメールを送信しました。メール内のリンクからパスワードを変更してください。'),
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
