import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recolle/features/account/account_page.dart';
import 'package:recolle/features/records/screens/home_screen.dart';
import 'package:recolle/components/scaffold_with_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ナビゲーションの状態を管理するためのキー
// ダイアログ表示などを制御する際に必要になります
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _accountNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'account');

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _authRefresh = _GoRouterRefreshStream(
  Supabase.instance.client.auth.onAuthStateChange,
);

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: _authRefresh,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;

    final isLoginRoute = state.matchedLocation == '/login';

    if (!loggedIn) {
      return isLoginRoute ? null : '/login';
    }

    if (isLoginRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const AccountPage()),
    // StatefulShellRoute: タブ切り替え時に各画面の状態（スクロール位置など）を保持するためのルート
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // ナビゲーションバーを含む共通の枠組み（Scaffold）を返します
        // navigationShellは現在表示すべき画面やタブの制御情報を持ちます
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // 1つ目のタブ：ホーム画面
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        // 2つ目のタブ：アカウント画面
        StatefulShellBranch(
          navigatorKey: _accountNavigatorKey,
          routes: [
            GoRoute(
              path: '/account',
              builder: (context, state) => const AccountPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
