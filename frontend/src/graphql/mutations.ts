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

// 質問を開始（管理者用）
export const START_QUESTION = gql`
  mutation StartQuestion($questionId: ID!) {
    startQuestion(input: { questionId: $questionId }) {
      currentQuizState {
        id
        quizActive
        questionActive
        questionStartedAt
        questionEndsAt
        durationSeconds
        remainingSeconds
        question {
          id
          questionNumber
        }
      }
      errors
    }
  }
`;

// 全プレイヤーセッションをリセット
export const RESET_ALL_PLAYER_SESSIONS = gql`
  mutation ResetAllPlayerSessions {
    resetAllPlayerSessions(input: {}) {
      success
      deletedCount
      errors
    }
  }
`;

// クイズを開始（管理者用）
export const START_QUIZ = gql`
  mutation StartQuiz {
    startQuiz(input: {}) {
      currentQuizState {
        id
        quizActive
        questionActive
        questionStartedAt
        questionEndsAt
        durationSeconds
        remainingSeconds
        question {
          id
          questionNumber
        }
      }
      errors
    }
  }
`;

// クイズを停止（管理者用）
export const STOP_QUIZ = gql`
  mutation StopQuiz {
    stopQuiz(input: {}) {
      currentQuizState {
        id
        quizActive
        questionActive
        questionStartedAt
        questionEndsAt
        durationSeconds
        remainingSeconds
        question {
          id
          questionNumber
        }
      }
      errors
    }
  }
`;
