# re2q デプロイメントガイド

このドキュメントは、re2q を AWS EC2 に Kamal 2 を使ってデプロイする手順をまとめたものです。

## 前提条件

- AWS EC2 インスタンスが起動済み
- AWS Elastic IP で IPv4 アドレスが固定済み
- ドメイン `re2q.smalruby.app` が設定済み
- DockerHub アカウント (`takaokouji`) が利用可能
- ローカル環境に Docker がインストール済み

## 推奨 EC2 スペック

400人同時アクセスを想定:

- **インスタンスタイプ**: t3.medium 以上
- **CPU**: 2 vCPU 以上
- **メモリ**: 4GB 以上
- **ストレージ**: 20GB 以上

## セキュリティグループ設定

以下のインバウンドルールを設定:

| プロトコル | ポート | ソース | 用途 |
|----------|--------|--------|------|
| SSH | 22 | デプロイ元IPのみ | SSH接続 |
| HTTP | 80 | 0.0.0.0/0 | Let's Encrypt自動認証 |
| HTTPS | 443 | 0.0.0.0/0 | アプリケーションアクセス |

## デプロイ手順

### 1. EC2 IP アドレスの設定

`config/deploy.yml` の `REPLACE_WITH_EC2_IP` を実際の Elastic IP に置き換え:

```yaml
servers:
  web:
    - xxx.xxx.xxx.xxx  # 実際のElastic IP
```

### 2. DockerHub アクセストークンの取得

1. https://hub.docker.com/settings/security にアクセス
2. 新しいアクセストークンを生成
3. トークンをコピー (形式: `dckr_pat_xxxxx`)

### 3. 環境変数の設定

```bash
# DockerHub アクセストークンを環境変数に設定
export KAMAL_REGISTRY_PASSWORD=dckr_pat_xxxxx
```

**注意**: `.kamal/secrets` は自動的に `config/master.key` を読み込みます。

### 4. 初回セットアップ

```bash
# Kamal バージョン確認
bundle exec kamal version

# サーバーへの初期セットアップ (Docker, Traefik など)
bundle exec kamal setup
```

**`kamal setup` の処理内容**:
- Docker のインストール・設定
- Kamal の依存関係インストール
- Traefik プロキシのセットアップ (SSL/TLS 自動化)
- Docker ネットワーク作成

### 5. 初回デプロイ

```bash
# イメージビルド & デプロイ
bundle exec kamal deploy
```

**デプロイフロー**:
1. Dockerfile からイメージビルド (フロントエンド含む)
2. DockerHub へプッシュ
3. EC2 サーバーでイメージプル
4. コンテナ起動
5. データベースマイグレーション (`bin/docker-entrypoint` 経由)
6. ゼロダウンタイムでトラフィック切替

### 6. 問題データの登録

デプロイ後、問題データを登録:

```bash
# サンプルデータを使う場合
bundle exec kamal app exec -i "bin/rails quiz:load_questions JSON_FILE=docs/samples/questions.json.example"

# カスタムデータを使う場合 (事前にサーバーにアップロード)
bundle exec kamal app exec -i "bin/rails quiz:load_questions JSON_FILE=/path/to/questions.json"
```

**問題データフォーマット**:

```json
[
  {
    "content": "問題文",
    "correct_answer": true,
    "duration_seconds": 15
  }
]
```

- `content`: 問題文 (文字列)
- `correct_answer`: 正解 (true=◯, false=✗)
- `duration_seconds`: 回答受付時間 (秒)

### 7. 動作確認

#### 利用者画面
```
https://re2q.smalruby.app/frontend/
```

確認項目:
- ◯/✗ ボタンが表示される
- 回答履歴エリアが表示される

#### 管理者画面
```
https://re2q.smalruby.app/frontend/admin
```

確認項目:
- 問題一覧が表示される
- クイズ開始ボタンが表示される

#### 回答集計テスト

1. 管理者画面でクイズを開始
2. 管理者画面で質問を開始
3. 利用者画面で回答を送信
4. 回答履歴に反映されることを確認

## 運用コマンド

### ログ確認

```bash
# リアルタイムログ
bundle exec kamal app logs -f

# 直近のログ
bundle exec kamal app logs --tail 100
```

### アプリケーション再起動

```bash
bundle exec kamal app restart
```

### 再デプロイ (コード更新時)

```bash
# コードを更新後
bundle exec kamal deploy
```

### ロールバック

```bash
# 以前のバージョンに戻す
bundle exec kamal rollback [VERSION]
```

### コンソール接続

```bash
# Rails コンソール
bundle exec kamal app exec -i "bin/rails console"

# データベースコンソール
bundle exec kamal app exec -i "bin/rails dbconsole"

# Bash シェル
bundle exec kamal app exec -i "bash"
```

### クイズ管理

```bash
# クイズ開始
bundle exec kamal app exec -i "bin/rails quiz:start"

# 質問開始 (次の質問を自動選択)
bundle exec kamal app exec -i "bin/rails quiz:start_question"

# 特定の質問を開始
bundle exec kamal app exec -i "bin/rails quiz:start_question POSITION=3"

# クイズリセット (回答・プレイヤー削除)
bundle exec kamal app exec -i "bin/rails quiz:reset"

# 全データリセット (質問含む)
bundle exec kamal app exec -i "bin/rails quiz:reset_all"
```

## データ永続化

### ストレージボリューム

`config/deploy.yml` で定義されたボリューム:

```yaml
volumes:
  - "re2q_storage:/rails/storage"
```

**保存されるデータ**:
- SQLite データベース (primary, cache, queue)
- Active Storage ファイル

### バックアップ推奨

定期的に `storage/` ディレクトリをバックアップすることを推奨:

```bash
# サーバーにSSH接続してバックアップ
ssh user@xxx.xxx.xxx.xxx
docker cp re2q-web:/rails/storage ./backup-$(date +%Y%m%d)
```

## パフォーマンスチューニング

### 環境変数

`config/deploy.yml` で設定:

```yaml
env:
  clear:
    SOLID_QUEUE_IN_PUMA: true
    WEB_CONCURRENCY: 4  # CPUコア数に応じて調整
    RAILS_MAX_THREADS: 5
```

**推奨設定** (400人同時アクセス):
- `WEB_CONCURRENCY`: 4 (t3.medium の 2 vCPU × 2)
- `RAILS_MAX_THREADS`: 5 (デフォルト)

### Solid Queue/Cache

- **Solid Queue**: Puma 内で実行 (`SOLID_QUEUE_IN_PUMA=true`)
- **Solid Cache**: SQLite ベース、超高速回答受付に使用

負荷が増えた場合は専用ジョブサーバーへの分離を検討。

## トラブルシューティング

### デプロイが失敗する

```bash
# 詳細ログを確認
bundle exec kamal deploy --verbose

# サーバーの状態確認
bundle exec kamal app details
```

### SSL証明書が取得できない

Let's Encrypt の制限に注意:
- HTTP (80番ポート) が開いていることを確認
- ドメインのDNS設定が正しいか確認
- レート制限に達していないか確認 (同一ドメイン: 50件/週)

### データベースエラー

```bash
# データベースコンソールで確認
bundle exec kamal app exec -i "bin/rails dbconsole"

# マイグレーション実行
bundle exec kamal app exec -i "bin/rails db:migrate"
```

## 参考リンク

- [Kamal 2 公式ドキュメント](https://kamal-deploy.org/)
- [re2q プロジェクト](https://github.com/takaokouji/re2q)
- [Issue #45: AWS へのデプロイ](https://github.com/takaokouji/re2q/issues/45)
