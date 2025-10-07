import { useQuery as useApolloQuery, useMutation as useApolloMutation } from '@apollo/client/react'
import './App.css'
import { AnswerScreen } from './components/AnswerScreen'
import { GET_QUIZ_DATA } from './graphql/queries'
import { SUBMIT_ANSWER } from './graphql/mutations'

interface Answer {
  id: string;
  player: {
    id: string;
  };
  playerAnswer: boolean;
  answeredAt: string;
  question: {
    id: string;
    questionNumber: number;
  };
}

interface QuizState {
  id: string;
  quizActive: boolean;
  questionStartedAt: string | null;
  questionEndsAt: string | null;
  durationSeconds: number | null;
  questionActive: boolean;
  remainingSeconds: number;
  question: {
    id: string;
    questionNumber: number;
  } | null;
}

interface QuizData {
  currentQuizState: QuizState | null;
  myAnswers: Answer[];
}

interface SubmitAnswerData {
  submitAnswer: {
    questionId: string | null;
    errors: string[];
  };
}

interface SubmitAnswerVariables {
  answer: boolean;
}

function App() {
  const { data, loading, error, refetch } = useApolloQuery<QuizData>(GET_QUIZ_DATA);

  const [submitAnswerMutation] = useApolloMutation<SubmitAnswerData, SubmitAnswerVariables>(
    SUBMIT_ANSWER
  );

  const handleSubmitAnswer = async (answer: boolean) => {
    try {
      const result = await submitAnswerMutation({
        variables: { answer },
      });

      if (result.data?.submitAnswer.errors && result.data.submitAnswer.errors.length > 0) {
        console.error('Submit failed:', result.data.submitAnswer.errors);
        throw new Error(result.data.submitAnswer.errors.join(', '));
      }
    } catch (err) {
      console.error('Failed to submit answer:', err);
      throw err;
    }
  };

  const handleCooldownEnd = async () => {
    try {
      await refetch();
    } catch (err) {
      console.error('Failed to refetch quiz data:', err);
    }
  };

  if (error) {
    return (
      <div style={{ padding: '20px', textAlign: 'center' }}>
        <h2>エラーが発生しました</h2>
        <p>{error.message}</p>
      </div>
    );
  }

  return (
    <AnswerScreen
      quizState={data?.currentQuizState || null}
      answers={data?.myAnswers || []}
      onSubmitAnswer={handleSubmitAnswer}
      onCooldownEnd={handleCooldownEnd}
      loading={loading && !data}
    />
  );
}

export default App
