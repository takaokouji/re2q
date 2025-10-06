# re2q - Realtime Two-Choice Quiz

リアルタイム二択クイズアプリケーション

## プロジェクト概要

re2qは、最大400人が同時参加可能なリアルタイム二択クイズシステムです。QRコードを使った簡単なアクセスと、高速な回答受付を実現します。

## 技術スタック

### バックエンド
- **Ruby** 3.4.6
- **Rails** 8.0.3
- **SQLite** (開発・本番DB)
- **Solid Cache** (高速回答受付用一時ストレージ)
- **Solid Queue** (非同期ジョブ処理)
- **GraphQL** (API)

### フロントエンド
- React
- TypeScript
- Apollo Client

## 開発環境のセットアップ

### 前提条件
- Ruby 3.4.6以上
- Rails 8.0.3以上
- SQLite3

### インストール手順

```bash
# リポジトリのクローン
git clone https://github.com/takaokouji/re2q.git
cd re2q

# 依存関係のインストール
bundle install

# データベースのセットアップ
bin/rails db:create
bin/rails db:migrate

# 開発サーバーの起動
bin/dev

# Solid Queueワーカーの起動（別ターミナル）
bin/jobs
```

## アーキテクチャ

### 高速回答受付の仕組み
```
利用者の回答 → Solid Cache (超高速書き込み)
                    ↓
            Solid Queue Job (1秒間隔)
                    ↓
            SQLite DB (バッチで永続化)
```

400人の瞬間的な書き込み負荷を捌くため、回答はまずSolid Cacheに格納され、Solid Queueの非同期Jobが1秒間隔でDBに永続化します。

### セッション管理
- QRコードアクセス時に一意の `player_uuid` をCookieで発行
- 端末を永続的に識別し、回答履歴と紐づけ

## 主要機能

### 利用者向け機能
- QRコードによるアクセス
- ◯/✗の回答ボタン
- 回答履歴の表示

### 管理者向け機能
- クイズ/質問管理
- クイズ状態制御（開始/終了）
- リアルタイムランキング表示
- セッション管理

## テスト

```bash
# テストの実行
bin/rails test
bin/rails test:system
```

## デプロイ

```bash
# Kamalを使用したデプロイ
kamal setup
kamal deploy
```

## ライセンス

MIT License

## 貢献

Issue、Pull Requestを歓迎します。

## 詳細設計

詳細な設計情報については [CLAUDE.md](CLAUDE.md) を参照してください。
