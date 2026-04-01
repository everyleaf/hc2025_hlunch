# hlunch

![hlunch ロゴ](./images/logo.png)

ハルシネーション・ランチ

![トップページ](./images/screenshot_index.png)
![レシピ詳細ページ](./images/screenshot_recipes.png)

## 開発環境セットアップ

```bash
cp .env.example .env
vim .env # OpenAIのAPIキーが必要です
bin/dev
```

## Renderへのデプロイ

### 1. Web Serviceの作成

1. Render ダッシュボードで **New > Web Service** を作成
2. GitHubリポジトリを接続
3. 以下を設定:
   - **Language**: `Docker`
   - **Region**: 任意

### 2. 永続ディスクの設定

> **注意**: 無料プランではPersistent Diskは使用できないため、**再デプロイや再起動のたびにDBデータが消える**。

有料プランでデータを保持する場合:

- **Mount Path**: `/rails/storage`
- **Size**: 任意（1GB程度）

### 3. 環境変数の設定

| 変数名 | 値 | 備考 |
|---|---|---|
| `RAILS_MASTER_KEY` | `config/master.key` の内容 | 必須 |
| `OPENAI_API_KEY` | OpenAI APIキー | 必須 |
| `OPENAI_API_BASE` | `https://api.openai.com/v1/` | 必須 |
| `BASIC_AUTH_USERNAME` | BASIC認証のユーザー名 | 任意（両方設定時のみ有効） |
| `BASIC_AUTH_PASSWORD` | BASIC認証のパスワード | 任意（両方設定時のみ有効） |
| `EPHEMERAL_STORAGE` | `true` | 任意（navbarにデータ未永続化の警告を表示） |

---

## 概要

料理レシピ生成を目的としたLLMアプリケーション

- ユーザーはプロンプトを保存できる
- 保存したプロンプトからLLMを使ってレシピを生成し保存できる
- プロンプト同士をLLMに合成させて新たなプロンプトを生成できる
