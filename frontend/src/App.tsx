import { useQuery as useApolloQuery, useMutation as useApolloMutation } from '@apollo/client/react'
import './App.css'
import { AnswerScreen } from './components/AnswerScreen'
import { AdminLogin } from './components/AdminLogin'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import { GET_QUIZ_DATA } from './graphql/queries'
import { SUBMIT_ANSWER } from './graphql/mutations'
import { Box, Text } from '@chakra-ui/react'

interface Player {
  id: string;
  name: string;
}

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
  me: Player | null;
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

function AppContent() {
  const { admin, loading: authLoading } = useAuth();
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

  if (authLoading) {
    return <Box p="20px" textAlign="center"><Text>Loading...</Text></Box>;
  }

  // /admin パスの場合は管理画面を表示
  if (window.location.pathname === '/admin') {
    return admin ? (
      <Box p="20px" textAlign="center">
        <Text fontSize="2xl" mb="20px">管理ダッシュボード</Text>
        <Text>ようこそ、{admin.username}さん</Text>
        <Text mt="10px" color="gray.500">（管理機能は今後実装予定）</Text>
      </Box>
    ) : (
      <AdminLogin />
    );
  }

  // 利用者画面
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
      me={data?.me || null}
      quizState={data?.currentQuizState || null}
      answers={data?.myAnswers || []}
      onSubmitAnswer={handleSubmitAnswer}
      onCooldownEnd={handleCooldownEnd}
      loading={loading && !data}
    />
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App
