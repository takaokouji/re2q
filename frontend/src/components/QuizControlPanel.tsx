import { useState, useEffect } from 'react';
import { useQuery, useMutation } from '@apollo/client/react';
import { GET_CURRENT_QUIZ_STATE, GET_QUESTIONS } from '../graphql/queries';
import { START_QUESTION } from '../graphql/mutations';
import { Box, Button, Heading, Text, Stack, SimpleGrid, Card, Badge } from '@chakra-ui/react';

interface Question {
  id: string;
  questionNumber: number;
  content: string;
  correctAnswer: boolean;
  durationSeconds: number;
}

interface QuizState {
  id: string;
  quizActive: boolean;
  questionActive: boolean;
  questionStartedAt: string | null;
  questionEndsAt: string | null;
  durationSeconds: number | null;
  remainingSeconds: number;
  question: {
    id: string;
    questionNumber: number;
  } | null;
}

interface GetQuestionsData {
  questions: Question[];
}

interface GetCurrentQuizStateData {
  currentQuizState: QuizState;
}

interface StartQuestionData {
  startQuestion: {
    currentQuizState: QuizState;
    errors: string[];
  };
}

interface StartQuestionVariables {
  questionId: string;
}

export function QuizControlPanel() {
  const [remainingSeconds, setRemainingSeconds] = useState<number>(0);
  const [visibleAnswers, setVisibleAnswers] = useState<Set<string>>(new Set());

  // CurrentQuizStateを5秒ごとにポーリング
  const { data: stateData } = useQuery<GetCurrentQuizStateData>(GET_CURRENT_QUIZ_STATE, {
    pollInterval: 5000,
  });

  useEffect(() => {
    if (stateData?.currentQuizState) {
      setRemainingSeconds(stateData.currentQuizState.remainingSeconds);
    }
  }, [stateData?.currentQuizState.remainingSeconds]);

  // 質問一覧を取得
  const { data: questionsData, loading: questionsLoading } = useQuery<GetQuestionsData>(GET_QUESTIONS);

  // startQuestion Mutation
  const [startQuestion, { loading: startLoading, error: startError }] = useMutation<
    StartQuestionData,
    StartQuestionVariables
  >(START_QUESTION, {
    refetchQueries: [{ query: GET_CURRENT_QUIZ_STATE }],
  });

  const handleStartQuestion = (questionId: string) => {
    startQuestion({ variables: { questionId } });
  };

  const toggleAnswerVisibility = (questionId: string) => {
    setVisibleAnswers((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(questionId)) {
        newSet.delete(questionId);
      } else {
        newSet.add(questionId);
      }
      return newSet;
    });
  };

  console.log('remainingSeconds:', remainingSeconds);
  useEffect(() => {
    console.log('remainingSeconds updated:', remainingSeconds);
    if (remainingSeconds > 0) {
      const timer = setTimeout(() => {
        setRemainingSeconds(remainingSeconds - 1);
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [remainingSeconds]);

  const state = stateData?.currentQuizState;

  return (
    <Box maxW="1200px" mx="auto" p="20px">
      <Heading size="xl" mb="30px">クイズ制御パネル</Heading>

      {/* CurrentQuizState表示 */}
      <Card.Root mb="30px" bg="blue.50">
        <Card.Header>
          <Heading size="md">現在の状態</Heading>
        </Card.Header>
        <Card.Body>
          <Stack gap="10px">
            <Box>
              <Text fontWeight="bold" display="inline">クイズ状態: </Text>
              {state?.quizActive ? (
                <Badge colorScheme="green">アクティブ</Badge>
              ) : (
                <Badge colorScheme="gray">停止中</Badge>
              )}
            </Box>
            <Box>
              <Text fontWeight="bold" display="inline">現在の質問: </Text>
              <Text display="inline">
                {state?.question ? `第${state.question.questionNumber}問` : 'なし'}
              </Text>
            </Box>
            <Box>
              <Text fontWeight="bold" display="inline">質問状態: </Text>
              {state?.questionActive ? (
                <Badge colorScheme="green">受付中</Badge>
              ) : (
                <Badge colorScheme="gray">終了</Badge>
              )}
            </Box>
            <Box>
              <Text fontWeight="bold" display="inline">残り時間: </Text>
              <Text display="inline">{remainingSeconds}秒</Text>
            </Box>
            {state?.questionStartedAt && (
              <Box>
                <Text fontWeight="bold" display="inline">開始時刻: </Text>
                <Text display="inline">{new Date(state.questionStartedAt).toLocaleString()}</Text>
              </Box>
            )}
            {state?.questionEndsAt && (
              <Box>
                <Text fontWeight="bold" display="inline">終了時刻: </Text>
                <Text display="inline">{new Date(state.questionEndsAt).toLocaleString()}</Text>
              </Box>
            )}
          </Stack>
        </Card.Body>
      </Card.Root>

      {/* エラー表示 */}
      {startError && (
        <Box mb="20px" p="15px" bg="red.100" borderRadius="md">
          <Text color="red.700" fontWeight="bold">エラー:</Text>
          <Text color="red.700">{startError.message}</Text>
        </Box>
      )}

      {/* 質問一覧 */}
      <Heading size="md" mb="20px">質問一覧</Heading>
      {questionsLoading ? (
        <Text>読み込み中...</Text>
      ) : (
        <SimpleGrid columns={{ base: 1, md: 2 }} gap="15px">
          {questionsData?.questions.map((question) => (
            <Card.Root key={question.id}>
              <Card.Header>
                <Heading size="sm">第{question.questionNumber}問</Heading>
              </Card.Header>
              <Card.Body>
                <Stack gap="10px">
                  <Text fontSize="sm">{question.content}</Text>
                  <Box>
                    <Text fontSize="xs" color="gray.600">
                      <Text
                        as="span"
                        cursor="pointer"
                        onClick={() => toggleAnswerVisibility(question.id)}
                        textDecoration="underline"
                      >
                        正解:
                      </Text>
                      {visibleAnswers.has(question.id) && ` ${question.correctAnswer ? '◯' : '✗'}`} | 制限時間: {question.durationSeconds}秒
                    </Text>
                  </Box>
                </Stack>
              </Card.Body>
              <Card.Footer>
                <Button
                  onClick={() => handleStartQuestion(question.id)}
                  disabled={startLoading || state?.questionActive}
                  colorPalette="blue"
                  bg="colorPalette.solid"
                  size="sm"
                  w="100%"
                >
                  {startLoading ? '開始中...' : '開始'}
                </Button>
              </Card.Footer>
            </Card.Root>
          ))}
        </SimpleGrid>
      )}
    </Box>
  );
}
