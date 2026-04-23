import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:recolle/core/auth/auth_reauth_in_progress.dart';
import 'package:recolle/core/utils/error_messages.dart';
import 'package:recolle/core/theme/app_colors.dart';
import 'package:recolle/features/account/account_auth_guard.dart';
import 'package:recolle/features/account/providers/auth_providers.dart';
import 'package:recolle/features/account/providers/auth_service_provider.dart';
import 'package:recolle/features/account/widgets/account_profile_card.dart';
import 'package:recolle/features/account/widgets/account_signed_in_panel.dart';
import 'package:recolle/features/account/widgets/account_signed_out_panel.dart';

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

    Future<void> runGuarded(Future<void> Function() fn) async {
      await runAccountAuthGuarded(
        context: context,
        isBusy: () => isBusy.value,
        setBusy: (v) => isBusy.value = v,
        emailController: emailController,
        authService: authService,
        fn: fn,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Account',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
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
          return ListenableBuilder(
            listenable: AuthReauthInProgress.instance,
            builder: (context, child) {
              // signOut 直後〜 signInAnonymously 完了まで一瞬 [user] が null になる。
              // その区間を「未接続」と出すと、ログアウト操作直後に謎の画面になる。
              if (user == null && AuthReauthInProgress.instance.isInProgress) {
                return const Center(child: CircularProgressIndicator());
              }

              final email = user?.email;
              final isAnonymous = user?.isAnonymous ?? false;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AccountProfileCard(
                    title: user == null
                        ? '未接続'
                        : (email != null && email.isNotEmpty
                              ? email
                              : (isAnonymous ? '未登録' : 'アカウント')),
                    subtitle: user == null
                        ? '下の「匿名IDで接続」から利用を再開するか、登録（任意）'
                        : (isAnonymous ? '' : '登録中'),
                  ),
                  const SizedBox(height: 16),
                  if (user == null)
                    AccountSignedOutPanel(
                      emailController: emailController,
                      passwordController: passwordController,
                      passwordConfirmController: passwordConfirmController,
                      isBusy: isBusy.value,
                      isSignup: isSignup.value,
                      isAnonymous: false,
                      showConnectionRecovery: true,
                      onToggleSignupMode: () {
                        isSignup.value = !isSignup.value;
                        if (isSignup.value) {
                          passwordConfirmController.clear();
                        }
                      },
                      runGuarded: runGuarded,
                      authService: authService,
                    )
                  else if (isAnonymous)
                    AccountSignedOutPanel(
                      emailController: emailController,
                      passwordController: passwordController,
                      passwordConfirmController: passwordConfirmController,
                      isBusy: isBusy.value,
                      isSignup: isSignup.value,
                      isAnonymous: true,
                      showConnectionRecovery: false,
                      onToggleSignupMode: () {
                        isSignup.value = !isSignup.value;
                        if (isSignup.value) {
                          passwordConfirmController.clear();
                        }
                      },
                      runGuarded: runGuarded,
                      authService: authService,
                    )
                  else
                    AccountSignedInPanel(
                      isBusy: isBusy.value,
                      runGuarded: runGuarded,
                      authService: authService,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
