import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recolle/account_page.dart';
import 'package:recolle/features/home/home_screen.dart';
import 'package:recolle/widgets/scaffold_with_navbar.dart';

// ナビゲーションの状態を管理するためのキー
// ダイアログ表示などを制御する際に必要になります
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _accountNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'account');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
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
