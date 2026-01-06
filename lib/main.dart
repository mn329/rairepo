import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recolle/core/router/router.dart';
import 'package:recolle/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .envファイルをロード
  await dotenv.load(fileName: ".env");

  // Supabaseの初期化
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 匿名ログイン (セッションがない場合のみ)
  // 注意: Supabase管理画面の Authentication > Providers で Anonymous Sign-ins を有効にする必要があります
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      debugPrint('Auth error: $e');
    }
  }

  // 1. ProviderScope: Riverpodの状態管理をアプリ全体で使えるようにする
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. MaterialApp.router: GoRouterを使ったナビゲーション機能付きのアプリ定義
    return MaterialApp.router(
      title: 'Live Report',
      debugShowCheckedModeBanner: false, // 右上の「Debug」帯を消す
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
