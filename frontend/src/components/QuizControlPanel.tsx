import { useState, useEffect, useRef } from 'react';
import { useQuery, useMutation } from '@apollo/client/react';
import { Box, Button, Heading, Text, Stack, SimpleGrid, Card, Badge, Dialog, CloseButton, Portal, IconButton, Menu } from '@chakra-ui/react';
import { Toaster, toaster } from "@/components/ui/toaster";

import { GET_CURRENT_QUIZ_STATE, GET_QUESTIONS } from '../graphql/queries';
import { START_QUESTION, RESET_ALL_PLAYER_SESSIONS, START_QUIZ, STOP_QUIZ, ADMIN_LOGOUT } from '../graphql/mutations';
import { RankingPanel } from './RankingPanel';

// (interface definitions remain the same)
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

interface ResetSessionsData {
  resetAllPlayerSessions: {
    success: boolean;
    deletedCount: number;
    errors: string[];
  };
}

interface StartQuizData {
  startQuiz: {
    currentQuizState: QuizState;
    errors: string[];
  };
}

interface StopQuizData {
  stopQuiz: {
    currentQuizState: QuizState;
    errors: string[];
  };
}

interface AdminLogoutData {
  adminLogout: {
    success: boolean;
  };
}

export function QuizControlPanel() {
  const [remainingSeconds, setRemainingSeconds] = useState<number>(0);
  const [visibleAnswers, setVisibleAnswers] = useState<Set<string>>(new Set());
  const [isResetAlertOpen, setIsResetAlertOpen] = useState(false);
  const currentQuizStateRef = useRef<HTMLDivElement | null>(null);

  const { data: stateData, refetch: refetchCurrentQuizStateData } = useQuery<GetCurrentQuizStateData>(GET_CURRENT_QUIZ_STATE);

  useEffect(() => {
    if (stateData?.currentQuizState) {
      setRemainingSeconds(stateData.currentQuizState.remainingSeconds);

      currentQuizStateRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [stateData?.currentQuizState]);

  const { data: questionsData, loading: questionsLoading } = useQuery<GetQuestionsData>(GET_QUESTIONS);

  const [startQuestion, { loading: startLoading, error: startError }] = useMutation<
    StartQuestionData,
    StartQuestionVariables
  >(START_QUESTION, {
    refetchQueries: [{ query: GET_CURRENT_QUIZ_STATE }],
  });

  const [resetAllPlayerSessions, { loading: resetLoading }] = useMutation<ResetSessionsData>(
    RESET_ALL_PLAYER_SESSIONS,
    {
      onCompleted: (data) => {
        const { success, deletedCount, errors } = data.resetAllPlayerSessions;
        if (success) {
          toaster.create({
            title: '成功',
            description: `${deletedCount}件のプレイヤーセッションをリセットしました。`,
            type: 'success',
            duration: 5000,
            closable: true,
          });
        } else {
          toaster.create({
            title: 'エラー',
            description: `リセットに失敗しました: ${errors.join(', ')}`,
            type: 'error',
            duration: 9000,
            closable: true,
          });
        }
        setIsResetAlertOpen(false);
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `リセット中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000,
          closable: true,
        });
        setIsResetAlertOpen(false);
      },
    }
  );

  const [startQuiz, { loading: startQuizLoading }] = useMutation<StartQuizData>(
    START_QUIZ,
    {
      onCompleted: (data) => {
        const { errors } = data.startQuiz;
        if (errors && errors.length > 0) {
          toaster.create({
            title: 'エラー',
            description: `クイズ開始に失敗しました: ${errors.join(', ')}`,
            type: 'error',
            duration: 9000,
            closable: true,
          });
        } else {
          toaster.create({
            title: '成功',
            description: 'クイズを開始しました。',
            type: 'success',
            duration: 5000,
            closable: true,
          });
          refetchCurrentQuizStateData();
        }
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `クイズ開始中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000,
          closable: true,
        });
      },
    }
  );

  const [stopQuiz, { loading: stopQuizLoading }] = useMutation<StopQuizData>(
    STOP_QUIZ,
    {
      onCompleted: (data) => {
        const { errors } = data.stopQuiz;
        if (errors && errors.length > 0) {
          toaster.create({
            title: 'エラー',
            description: `クイズ停止に失敗しました: ${errors.join(', ')}`,
            type: 'error',
            duration: 9000,
            closable: true,
          });
        } else {
          toaster.create({
            title: '成功',
            description: 'クイズを停止しました。',
            type: 'success',
            duration: 5000,
            closable: true,
          });
          refetchCurrentQuizStateData();
        }
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `クイズ停止中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000,
          closable: true,
        });
      },
    }
  );

  const [adminLogout, { loading: logoutLoading }] = useMutation<AdminLogoutData>(
    ADMIN_LOGOUT,
    {
      onCompleted: async (data) => {
        if (data.adminLogout.success) {
          window.location.reload(); // Reload the page after logout
        } else {
          toaster.create({
            title: 'エラー',
            description: 'ログアウトに失敗しました。',
            type: 'error',
            duration: 9000,
            closable: true,
          });
        }
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `ログアウト中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000,
          closable: true,
        });
      },
    }
  );

  const handleStartQuestion = (questionId: string) => {
    startQuestion({ variables: { questionId } });
  };

  const handleResetSessions = () => {
    resetAllPlayerSessions();
  };

  const handleStartQuiz = () => {
    startQuiz();
  };

  const handleStopQuiz = () => {
    stopQuiz();
  };

  const handleLogout = () => {
    adminLogout();
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

  useEffect(() => {
    if (remainingSeconds > 0) {
      const timer = setTimeout(() => {
        setRemainingSeconds(remainingSeconds - 1);
      }, 1000);
      return () => clearTimeout(timer);
    } else {
      const timer = setTimeout(() => {
        refetchCurrentQuizStateData();
      }, 2000);
      return () => clearTimeout(timer);
    }
  }, [remainingSeconds]);

  const state = stateData?.currentQuizState;

  const isQuizFinished = !state?.quizActive && !state?.questionActive;

  return (
    <Box maxW="1200px" mx="auto" p="20px" position="relative">
      <Toaster />

      {/* 3ドットメニュー */}
      <Box position="absolute" top="20px" right="20px" zIndex={10}>
        <Menu.Root>
          <Menu.Trigger asChild>
            <IconButton
              variant="ghost"
              aria-label="メニュー"
              size="lg"
            >
              ⋮
            </IconButton>
          </Menu.Trigger>
          <Menu.Positioner>
            <Menu.Content>
              <Box px={4} py={2} fontWeight="bold" color="gray.700">
                クイズ制御パネル
              </Box>
              <Menu.Separator />
              <Menu.Item
                value="reset"
                onClick={() => setIsResetAlertOpen(true)}
                color="red.600"
              >
                全プレイヤーセッションリセット
              </Menu.Item>
              <Menu.Item
                value="logout"
                onClick={handleLogout}
                disabled={logoutLoading}
              >
                {logoutLoading ? 'ログアウト中...' : 'ログアウト'}
              </Menu.Item>
            </Menu.Content>
          </Menu.Positioner>
        </Menu.Root>
      </Box>

      <Box ref={currentQuizStateRef} height="60px" />

      {/* クイズ開始ボタン */}
      <Box mb="30px">
        {state?.quizActive ? (
          <Button
            colorPalette="red"
            bg="colorPalette.solid"
            onClick={handleStopQuiz}
            loading={stopQuizLoading}
            disabled={stopQuizLoading}
            w="100%"
          >
            {stopQuizLoading ? 'クイズ停止中...' : 'クイズ停止'}
          </Button>
        ) : (
          <Button
            colorPalette="green"
            bg="colorPalette.solid"
            onClick={handleStartQuiz}
            loading={startQuizLoading}
            disabled={startQuizLoading}
            w="100%"
          >
            {startQuizLoading ? 'クイズ開始中...' : 'クイズ開始'}
          </Button>
        )}
      </Box>

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
                <Badge colorPalette="green">アクティブ</Badge>
              ) : (
                <Badge colorPalette="gray">停止中</Badge>
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
                <Badge colorPalette="green">受付中</Badge>
              ) : (
                <Badge colorPalette="gray">終了</Badge>
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

      {/* ランキング表示 */}
      <Box mt="30px">
        <RankingPanel lottery={isQuizFinished} />
      </Box>

      {/* セッションリセット確認ダイアログ */}
      <Dialog.Root role="alertdialog"
        open={isResetAlertOpen}
        onExitComplete={() => setIsResetAlertOpen(false)}
      >
        <Portal>
          <Dialog.Backdrop />
          <Dialog.Positioner>
            <Dialog.Content>
              <Dialog.Header fontSize="lg" fontWeight="bold">
                <Dialog.Title>セッションリセットの確認</Dialog.Title>
              </Dialog.Header>
              <Dialog.Body>
                本当にすべてのプレイヤーセッションをリセットしますか？この操作は元に戻せません。
              </Dialog.Body>
              <Dialog.Footer>
                <Dialog.ActionTrigger asChild>
                  <Button variant="outline" onClick={() => setIsResetAlertOpen(false)}>キャンセル</Button>
                </Dialog.ActionTrigger>
                <Button colorPalette="red" bg="colorPalette.solid" onClick={handleResetSessions} ml={3} loading={resetLoading}>
                  リセット実行
                </Button>
              </Dialog.Footer>
              <Dialog.CloseTrigger asChild>
                <CloseButton size="sm" onClick={() => setIsResetAlertOpen(false)} />
              </Dialog.CloseTrigger>
            </Dialog.Content>
          </Dialog.Positioner>
        </Portal>
      </Dialog.Root>
    </Box>
  );
}
