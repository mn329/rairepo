# recolle

ライブ・映画・本などの体験を記録する Flutter アプリです。チケット画像・セットリスト・MC メモ・感想などをまとめて残せるデータモデルを中心に、Supabase 認証と連携した構成になっています。アプリ表示名（`MaterialApp` の `title`）は **recolle** です。

## 技術スタック

| 領域 | 利用パッケージ |
|------|----------------|
| ルーティング | [go_router](https://pub.dev/packages/go_router)（タブは `StatefulShellRoute` で各スタックの状態を保持） |
| バックエンド・認証 | [supabase_flutter](https://pub.dev/packages/supabase_flutter) |
| 状態管理 | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) / [hooks_riverpod](https://pub.dev/packages/hooks_riverpod)、[flutter_hooks](https://pub.dev/packages/flutter_hooks) |
| 環境変数 | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) |
| 画像選択 | [image_picker](https://pub.dev/packages/image_picker) |

Dart SDK: `^3.9.2`（`pubspec.yaml` 参照）

## セットアップ

1. リポジトリルートに `.env` を用意し、次のキーを設定します（値は Supabase ダッシュボードから取得）。

   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

2. `.env` は `pubspec.yaml` の `assets` に含まれているため、**機密をコミットしない**よう `.gitignore` で除外してください。

3. 依存関係の取得と実行:

   ```bash
   flutter pub get
   flutter run
   ```

## アプリの動き（概要）

- **未ログイン**: `/login`（アカウント画面）へ誘導。
- **ログイン後**: 下部ナビで **ホーム（`/`）** と **アカウント（`/account`）** の 2 タブ。認証状態は Supabase の `onAuthStateChange` を GoRouter の `refreshListenable` に渡し、セッション変化でルートを再評価します。

## プロジェクト構成（`lib/`）

- `core/` … ルーター、テーマ、定数、エラーメッセージなど共通基盤
- `features/records/` … レコード一覧・作成・詳細、モデル、プロバイダ
- `features/account/` … 認証サービス、プロバイダ、アカウント UI
- `components/` … ナビ付きスキャフォールド、チケット風カードなど

## 参考リンク

- [Flutter ドキュメント](https://docs.flutter.dev/)
