import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    final rng = useMemoized(() => Random.secure());

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
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(toUserFriendlyMessage(e))));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(toUserFriendlyMessage(e))));
        }
      } finally {
        isBusy.value = false;
      }
    }

    String generateTestEmail() {
      final ts = DateTime.now().millisecondsSinceEpoch;
      // 使い捨て前提のため example.com を利用（開発用）
      return 'test+$ts@example.com';
    }

    String generateTestPassword() {
      // Supabase 側の最小要件（6文字以上）を満たしつつ、毎回変わるようにする
      final n = rng.nextInt(900000) + 100000; // 6桁
      return 'Test$n!';
    }

    Future<void> showCredentialsDialog({
      required String email,
      required String password,
      required bool copied,
    }) async {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('テスト用アカウントを作成しました'),
          content: SelectableText(
            'メール: $email\nパスワード: $password'
            '${copied ? '\n\n（クリップボードにコピーしました）' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
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
          final userId = user?.id;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileCard(
                title: email ?? '未ログイン',
                subtitle: email == null ? 'ログインして利用を開始' : 'ログイン中',
                userId: userId,
                isAnonymous: user?.isAnonymous ?? false,
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          needsConfirm
                                              ? '登録しました。確認メールを送りました。リンクから認証してください。'
                                              : '登録しました',
                                        ),
                                      ),
                                    );
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
              if (kDebugMode && user == null) ...[
                const SizedBox(height: 16),
                _ExpandableSection(
                  title: '開発用（デバッグ）',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.tonal(
                        onPressed: isBusy.value
                            ? null
                            : () {
                                runGuarded(() async {
                                  await authService.signInAnonymously();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('匿名でログインしました（テスト）'),
                                    ),
                                  );
                                });
                              },
                        child: const Text('匿名でログイン（テスト）'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: isBusy.value
                            ? null
                            : () {
                                runGuarded(() async {
                                  final testEmail = generateTestEmail();
                                  final testPassword = generateTestPassword();

                                  await authService.signUpWithPassword(
                                    email: testEmail,
                                    password: testPassword,
                                  );

                                  // プロジェクト設定で確認メール必須の場合は signUp 直後にセッションが張られないことがあるため、
                                  // セッションが無い場合のみサインインを試みる。
                                  if (authService.currentSession == null) {
                                    await authService.signInWithPassword(
                                      email: testEmail,
                                      password: testPassword,
                                    );
                                  }

                                  var copied = false;
                                  try {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text:
                                            'メール: $testEmail\nパスワード: $testPassword',
                                      ),
                                    );
                                    copied = true;
                                  } catch (_) {
                                    copied = false;
                                  }

                                  if (!context.mounted) return;
                                  await showCredentialsDialog(
                                    email: testEmail,
                                    password: testPassword,
                                    copied: copied,
                                  );
                                });
                              },
                        child: const Text('テスト用アカウントを作成（自動）'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '注意: Supabase側で確認メールが必須だと、作成後すぐにログインできない場合があります。',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary.withAlpha(166),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
  const _ProfileCard({
    required this.title,
    required this.subtitle,
    required this.userId,
    required this.isAnonymous,
  });

  final String title;
  final String subtitle;
  final String? userId;
  final bool isAnonymous;

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
                if (userId != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'uid: ${_shortId(userId!)}${isAnonymous ? '（匿名）' : ''}',
                    style: TextStyle(
                      color: AppColors.textPrimary.withAlpha(128),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shortId(String id) {
  if (id.length <= 10) return id;
  return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
}

/// パスワードリセット用メール送信ダイアログを表示する。
void _showForgotPasswordDialog(
  BuildContext context,
  AuthService authService,
  Future<void> Function(Future<void> Function() fn) runGuarded,
) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('パスワードをリセット'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
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
