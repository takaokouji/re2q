import { gql } from '@apollo/client';

// 回答を送信
export const SUBMIT_ANSWER = gql`
  mutation SubmitAnswer($answer: Boolean!) {
    submitAnswer(input: { answer: $answer }) {
      myAnswers {
        id
        playerId
        questionId
        playerAnswer
        answeredAt
        question {
          id
          questionNumber
        }
      }
      errors
    }
  }
`;
