# CLAUDE.md - re2q プロジェクト開発ガイド

このドキュメントは、Claude Codeが `re2q` プロジェクトの開発を支援するための情報をまとめたものです。

## プロジェクト概要

**re2q (Realtime Two-Choice Quiz)** は、リアルタイム二択クイズアプリケーションです。

### 基本仕様
- **想定同時アクセス**: 400人
- **インフラ**: AWS EC2
- **構成**: モノレポ (Monolithic Repository)

## 技術スタック

### バックエンド
- **Ruby on Rails 8**
- **SQLite** (開発・本番DB)
- **Solid Cache** (高速回答受付用一時ストレージ)
- **Solid Queue** (非同期ジョブ処理)
- **GraphQL** (`graphql-ruby`)

### フロントエンド
- **React**
- **TypeScript**
- **Apollo Client**
- 格納場所: `re2q/frontend` ディレクトリ

## アーキテクチャの重要ポイント

### 1. リアルタイム性の実現
- **GraphQL Polling** を使用
- Action Cable（WebSocket）は**不使用**
- 利用者は定期的なGraphQL Queryで状態を取得して画面更新

### 2. 高速回答受付の仕組み
```
利用者の回答 → Solid Cache (超高速書き込み)
                    ↓
            Solid Queue Job (1秒間隔)
                    ↓
            SQLite DB (バッチで永続化)
```

- 400人の瞬間的な書き込み負荷を捌くため、回答はまず **Solid Cache** に格納
- **Solid Queue** の非同期Jobが1秒間隔でDBに永続化し、書き込み負荷を平滑化

### 3. セッション管理
- QRコードアクセス時に一意の **`player_uuid`** を発行
- HTTP Cookie (Secure, HttpOnly推奨) に格納
- 端末を永続的に識別し、回答履歴と紐づける
- 利用者からのリセットは不可（管理者のみ可能）

## 主要機能

### 利用者（回答者）の機能
1. **アクセス・認証**: QRコード経由でアクセス、`player_uuid` Cookie発行
2. **画面表示**: ◯/✗の回答ボタンとこれまでの回答履歴のみ表示（問題文は非表示）
3. **状態同期**: しない。回答時のレスポンスで状態更新
4. **回答**: いつでも可能。質問が `active` の時のみバックエンドで受付
5. **回答受付**: `submitAnswer` Mutation → Solid Cache格納 → DB履歴をレスポンス
6. **履歴更新**: レスポンスの履歴を即時表示（現在の回答は含まれない）

### 管理者の機能
1. **クイズ/質問管理**: 問題数（デフォルト8問）の登録・編集
2. **クイズ状態制御**:
   - クイズ全体の開始/終了
   - 各問の開始指示 (`startQuestion` Mutation)
     - 回答受付期間（秒、デフォルト10秒）を指定
     - Solid Cache → DB永続化Jobを開始
   - 各問の終了指示は行わない（受付期間終了と同時に自動終了）
3. **ランキング**:
   - 1秒間隔で非同期Job集計
   - 問題途中でも確認可能
   - 最終同点時の抽選機能
4. **セッションリセット**: 全利用者セッション一括リセット

## データモデル

### 主要モデル
- **`Player`**: uuid, 回答履歴との紐づけ
- **`Question`**: 正解、回答受付期間など
- **`Answer`**: player_id, question_id, 回答内容
- **`CurrentQuizState`**: 現在アクティブなクイズ、質問番号、回答受付期間

## 開発の優先順位

### High（最優先）
開発の基盤となるインフラ、認証、コア機能（超高速回答受付）

### Medium
管理者向け操作、ランキングの基礎、利用者のUXを向上させる機能

### Low
設定ファイルや周辺環境の整備

## 重要な設計方針

1. **回答受付の超高速化**: Solid Cacheを活用したDB書き込み負荷の平滑化
2. **シンプルな同期**: WebSocketを使わず、GraphQL Pollingで状態取得
3. **確実なセッション管理**: Cookie-basedの `player_uuid` で端末識別
4. **非同期処理の活用**: Solid Queueで負荷分散とランキング集計

## Claude Codeへの指示

### コーディング時の注意点
- Rails 8の最新機能を活用する
- Solid Cache/Queueの特性を理解した実装を行う
- GraphQL APIの設計は、フロントエンドの使いやすさを考慮する
- 400人同時アクセスを想定したパフォーマンスチューニングを意識する

### Issue対応時の流れ
1. Issue内容を確認
2. 関連する設計方針を CLAUDE.md で確認
3. 実装の影響範囲を検討
4. バックエンド・フロントエンド両方の整合性を確保
5. テストコードも合わせて実装

## 参考情報

- 初期設計Issue: https://github.com/takaokouji/re2q/issues/1
- プロジェクトリポジトリ: https://github.com/takaokouji/re2q
