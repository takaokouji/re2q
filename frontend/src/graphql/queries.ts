import { gql } from '@apollo/client';

// 現在のクイズ状態を取得
export const GET_CURRENT_QUIZ_STATE = gql`
  query GetCurrentQuizState {
    currentQuizState {
      id
      quizActive
      questionStartedAt
      questionEndsAt
      durationSeconds
      questionActive
      remainingSeconds
      question {
        id
        questionNumber
      }
    }
  }
`;

// 自分の回答履歴を取得
export const GET_MY_ANSWERS = gql`
  query GetMyAnswers {
    myAnswers {
      id
      playerId
      playerAnswer
      answeredAt
      question {
        id
        questionNumber
      }
    }
  }
`;

// クイズ状態と回答履歴を同時取得
export const GET_QUIZ_DATA = gql`
  query GetQuizData {
    currentQuizState {
      id
      quizActive
      questionStartedAt
      questionEndsAt
      durationSeconds
      questionActive
      remainingSeconds
      question {
        id
        questionNumber
      }
    }
    myAnswers {
      id
      player {
        id
      }
      playerAnswer
      answeredAt
      question {
        id
        questionNumber
      }
    }
  }
`;
