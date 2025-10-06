import { gql } from '@apollo/client'
import { useQuery } from '@apollo/client/react'
import './App.css'

const TEST_COOKIE_QUERY = gql`
  query TestCookieAuth {
    testField
    myAnswers {
      id
    }
  }
`

function App() {
  const { loading, error, data } = useQuery(TEST_COOKIE_QUERY)

  return (
    <div className="landing-page">
      <h1>re2q - リアルタイム二択クイズ</h1>

      <div className="card">
        <h2>Cookie認証テスト</h2>

        {loading && <p>認証中...</p>}

        {error && (
          <div className="error">
            <p>エラーが発生しました</p>
            <pre>{error.message}</pre>
          </div>
        )}

        {data && (
          <div className="success">
            <p>✓ Cookie認証が正常に動作しています</p>
            <p>GraphQL接続: {data.testField}</p>
            <p>回答履歴: {data.myAnswers.length}件</p>
            <details>
              <summary>詳細情報</summary>
              <pre>{JSON.stringify(data, null, 2)}</pre>
            </details>
          </div>
        )}
      </div>

      <div className="info">
        <p>このページにアクセスすると、自動的にプレイヤーIDがCookieに保存されます。</p>
        <p>ブラウザの開発者ツールでCookieを確認できます（暗号化されています）。</p>
      </div>
    </div>
  )
}

export default App
