import { gql } from '@apollo/client';

// 回答を送信
export const SUBMIT_ANSWER = gql`
  mutation SubmitAnswer($answer: Boolean!) {
    submitAnswer(input: { answer: $answer }) {
      errors
    }
  }
`;

// 管理者ログイン
export const ADMIN_LOGIN = gql`
  mutation AdminLogin($username: String!, $password: String!) {
    adminLogin(input: { username: $username, password: $password }) {
      admin {
        id
        username
      }
      errors
    }
  }
`;

// 管理者ログアウト
export const ADMIN_LOGOUT = gql`
  mutation AdminLogout {
    adminLogout(input: {}) {
      success
    }
  }
`;
