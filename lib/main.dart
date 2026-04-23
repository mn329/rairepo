import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recolle/core/router/router.dart';
import 'package:recolle/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// App Store: メール等の未登録でも使えるよう、起動直後に匿名セッションを保証する。
/// Supabase ダッシュボードで「Anonymous sign-ins」が有効なこと。
Future<void> _ensureAnonymousSession() async {
  final client = Supabase.instance.client;
  if (client.auth.currentSession != null) {
    return;
  }
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      await client.auth.signInAnonymously();
      return;
    } catch (e, st) {
      assert(() {
        debugPrint('Anonymous sign-in failed: $e\n$st');
        return true;
      }());
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .envファイルをロード
  await dotenv.load(fileName: ".env");

  // Supabaseの初期化

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  await _ensureAnonymousSession();

  attachEmailLinkAccountNavigation();

  // 1. ProviderScope: Riverpodの状態管理をアプリ全体で使えるようにする
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. MaterialApp.router: GoRouterを使ったナビゲーション機能付きのアプリ定義
    return MaterialApp.router(
      title: 'recolle',
      debugShowCheckedModeBanner: false,
      // 3. テーマ設定: 別ファイルの AppTheme クラスで定義したダークテーマを適用
      theme: AppTheme.darkTheme,

      // 4. ルーティング設定: router.dart で定義した画面遷移ルールを適用
      routerConfig: router,

      // 5. 日本語化設定: カレンダーや戻るボタンなどの標準UIを日本語にする
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP')],
    );
  }
}
