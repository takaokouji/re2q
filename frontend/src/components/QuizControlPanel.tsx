import { useState, useEffect, useRef } from 'react';
import { useQuery, useMutation } from '@apollo/client/react';
import { Box, Button, Heading, Text, Stack, SimpleGrid, Card, Dialog, CloseButton, Portal, IconButton, Menu, QrCode } from '@chakra-ui/react';
import { Toaster, toaster } from "@/components/ui/toaster";

import { GET_CURRENT_QUIZ_STATE, GET_QUESTIONS } from '../graphql/queries';
import { START_QUESTION, START_NEXT_QUESTION, RESET_ALL_PLAYER_SESSIONS, START_QUIZ, STOP_QUIZ, ADMIN_LOGOUT, RESET_QUIZ } from '../graphql/mutations';
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
    content: string;
    isLast: boolean;
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

interface ResetQuizData {
  resetQuiz: {
    success: boolean;
    deletedAnswersCount: number;
    deletedPlayersCount: number;
    errors: string[];
  };
}

interface StartNextQuestionData {
  startNextQuestion: {
    currentQuizState: QuizState;
    isLastQuestion: boolean;
    errors: string[];
  };
}

export function QuizControlPanel() {
  const [remainingSeconds, setRemainingSeconds] = useState<number>(0);
  const [visibleAnswers, setVisibleAnswers] = useState<Set<string>>(new Set());
  const [isResetAlertOpen, setIsResetAlertOpen] = useState(false);
  const [isResetQuizAlertOpen, setIsResetQuizAlertOpen] = useState(false);
  const [isLastQuestion, setIsLastQuestion] = useState<boolean>(false);
  const currentQuizStateRef = useRef<HTMLDivElement | null>(null);

  // QRコード用のURL取得
  const getPlayerUrl = () => {
    if (import.meta.env.PROD) {
      return window.location.origin;
    }
    return 'http://localhost:5173/';
  };

  const { data: stateData, refetch: refetchCurrentQuizStateData } = useQuery<GetCurrentQuizStateData>(GET_CURRENT_QUIZ_STATE);

  useEffect(() => {
    if (stateData?.currentQuizState) {
      setRemainingSeconds(stateData.currentQuizState.remainingSeconds);

      // 最後の問題かどうかを更新
      if (stateData.currentQuizState.question?.isLast) {
        setIsLastQuestion(true);
      }

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
            duration: 5000
          });
        } else {
          toaster.create({
            title: 'エラー',
            description: `リセットに失敗しました: ${errors.join(', ')}`,
            type: 'error',
            duration: 9000
          });
        }
        setIsResetAlertOpen(false);
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `リセット中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000
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
            duration: 9000
          });
        } else {
          toaster.create({
            title: '成功',
            description: 'クイズを開始しました。',
            type: 'success',
            duration: 5000
          });
          refetchCurrentQuizStateData();
        }
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `クイズ開始中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000
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
            duration: 9000
          });
        } else {
          toaster.create({
            title: '成功',
            description: 'クイズを停止しました。',
            type: 'success',
            duration: 5000
          });
          refetchCurrentQuizStateData();
        }
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `クイズ停止中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000
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
            duration: 9000
          });
        }
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `ログアウト中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000
        });
      },
    }
  );

  const [resetQuiz, { loading: resetQuizLoading }] = useMutation<ResetQuizData>(
    RESET_QUIZ,
    {
      onCompleted: (data) => {
        const { success, deletedAnswersCount, deletedPlayersCount, errors } = data.resetQuiz;
        if (success) {
          toaster.create({
            title: '成功',
            description: `クイズをリセットしました。（回答: ${deletedAnswersCount}件、プレイヤー: ${deletedPlayersCount}件を削除）`,
            type: 'success',
            duration: 5000
          });
          refetchCurrentQuizStateData();
          setIsLastQuestion(false);
        } else {
          toaster.create({
            title: 'エラー',
            description: `クイズリセットに失敗しました: ${errors.join(', ')}`,
            type: 'error',
            duration: 9000
          });
        }
        setIsResetQuizAlertOpen(false);
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `クイズリセット中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000
        });
        setIsResetQuizAlertOpen(false);
      },
    }
  );

  const [startNextQuestion, { loading: startNextLoading }] = useMutation<StartNextQuestionData>(
    START_NEXT_QUESTION,
    {
      onCompleted: (data) => {
        const { errors, isLastQuestion } = data.startNextQuestion;
        if (errors && errors.length > 0) {
          toaster.create({
            title: 'エラー',
            description: `次の問題開始に失敗しました: ${errors.join(', ')}`,
            type: 'error',
            duration: 9000
          });
        } else {
          setIsLastQuestion(isLastQuestion);
          toaster.create({
            title: '成功',
            description: '次の問題を開始しました。',
            type: 'success',
            duration: 5000
          });
          refetchCurrentQuizStateData();
        }
      },
      onError: (error) => {
        toaster.create({
          title: 'エラー',
          description: `次の問題開始中にエラーが発生しました: ${error.message}`,
          type: 'error',
          duration: 9000
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

  const handleResetQuiz = () => {
    resetQuiz();
  };

  const handleStartNextQuestion = () => {
    startNextQuestion();
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
    <Box maxW="1400px" mx="auto" p="20px" position="relative">
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
                value="reset-quiz"
                onClick={() => setIsResetQuizAlertOpen(true)}
                colorPalette="red"
                color="colorPalette.600"
              >
                クイズをリセット
              </Menu.Item>
              <Menu.Item
                value="reset"
                onClick={() => setIsResetAlertOpen(true)}
                colorPalette="red"
                color="colorPalette.600"
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

      {/* 大型スクリーン表示エリア（ポップなデザイン） */}
      <Box
        mb="40px"
        minH="70vh"
        borderRadius="20px"
        colorPalette={state?.quizActive ? 'green' : 'red'}
        bgGradient="to-br"
        gradientFrom="colorPalette.100"
        gradientTo="colorPalette.200"
        position="relative"
        p="40px"
        boxShadow="2xl"
      >
        {/* 中央エリア */}
        <Box
          display="flex"
          flexDirection="column"
          justifyContent="center"
          alignItems="center"
          minH="70vh"
          gap="40px"
        >
          {/* 問題番号（中央上部） */}
          {state?.question ? (
            <Text
              fontSize={{ base: '32px', md: '40px', lg: '48px' }}
              fontWeight="black"
              colorPalette='gray'
              color="colorPalette.800"
            >
              第 {state.question.questionNumber} 問
            </Text>
          ) : (
            <Text
              fontSize={{ base: '32px', md: '40px', lg: '48px' }}
              fontWeight="black"
              colorPalette='gray'
              color="colorPalette.800"
            >
              クイズ待機中
            </Text>
          )}

          {/* 問題文（中央配置） */}
          {state?.question && (
            <Text
              fontSize={{ base: '28px', md: '38px', lg: '48px' }}
              fontWeight="bold"
              colorPalette='gray'
              color="colorPalette.900"
              textAlign="center"
              lineHeight="1.5"
              maxW="90%"
            >
              {state.question.content}
            </Text>
          )}

          {/* 残り時間（数字のみ） */}
          <Text
            fontSize={{ base: '80px', md: '120px', lg: '160px' }}
            fontWeight="black"
            colorPalette={state?.questionActive ? (remainingSeconds > 5 ? 'green' : 'red') : 'gray'}
            color={state?.questionActive ? 'colorPalette.600' : 'colorPalette.400'}
            textAlign="center"
            lineHeight="1"
          >
            {remainingSeconds}
          </Text>
        </Box>

        {/* QRコード（左下） */}
        <Box position="absolute" bottom="20px" left="30px">
          <QrCode.Root value={getPlayerUrl()} size={{ base: 'lg', md: 'xl', lg: '2xl' }}>
            <QrCode.Frame>
              <QrCode.Pattern />
            </QrCode.Frame>
          </QrCode.Root>
        </Box>

        {/* 開始時刻・終了時刻（右下に小さく） */}
        <Box position="absolute" bottom="20px" right="30px">
          <Stack gap="5px" alignItems="flex-end">
            {state?.questionStartedAt && (
              <Text fontSize="12px" colorPalette="gray" color="colorPalette.600">
                開始: {new Date(state.questionStartedAt).toLocaleTimeString()}
              </Text>
            )}
            {state?.questionEndsAt && (
              <Text fontSize="12px" colorPalette="gray" color="colorPalette.600">
                終了: {new Date(state.questionEndsAt).toLocaleTimeString()}
              </Text>
            )}
          </Stack>
        </Box>
      </Box>

      {/* 管理者制御パネル */}
      {/* クイズ開始/次の問題/停止ボタン */}
      <Box mb="30px">
        {!state?.quizActive ? (
          <Button
            colorPalette="green"
            bg="colorPalette.solid"
            onClick={handleStartQuiz}
            loading={startQuizLoading}
            disabled={startQuizLoading}
            w="100%"
            size="lg"
          >
            {startQuizLoading ? 'クイズ開始中...' : 'クイズ開始'}
          </Button>
        ) : isLastQuestion ? (
          <Button
            colorPalette="red"
            bg="colorPalette.solid"
            onClick={handleStopQuiz}
            loading={stopQuizLoading}
            disabled={stopQuizLoading || state?.questionActive}
            w="100%"
            size="lg"
          >
            {stopQuizLoading ? 'クイズ停止中...' : 'クイズ停止'}
          </Button>
        ) : (
          <Button
            colorPalette="blue"
            bg="colorPalette.solid"
            onClick={handleStartNextQuestion}
            loading={startNextLoading}
            disabled={startNextLoading || state?.questionActive}
            w="100%"
            size="lg"
          >
            {startNextLoading ? '次の問題を開始中...' : '次の問題'}
          </Button>
        )}
      </Box>

      {/* エラー表示 */}
      {startError && (
        <Box mb="20px" p="15px" colorPalette="red" bg="colorPalette.100" borderRadius="md">
          <Text colorPalette="red" color="colorPalette.700" fontWeight="bold">エラー:</Text>
          <Text colorPalette="red" color="colorPalette.700">{startError.message}</Text>
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

      {/* クイズリセット確認ダイアログ */}
      <Dialog.Root role="alertdialog"
        open={isResetQuizAlertOpen}
        onExitComplete={() => setIsResetQuizAlertOpen(false)}
      >
        <Portal>
          <Dialog.Backdrop />
          <Dialog.Positioner>
            <Dialog.Content>
              <Dialog.Header fontSize="lg" fontWeight="bold">
                <Dialog.Title>クイズリセットの確認</Dialog.Title>
              </Dialog.Header>
              <Dialog.Body>
                本当にクイズをリセットしますか？クイズ状態、すべての回答、プレイヤーが削除されます。この操作は元に戻せません。
              </Dialog.Body>
              <Dialog.Footer>
                <Dialog.ActionTrigger asChild>
                  <Button variant="outline" onClick={() => setIsResetQuizAlertOpen(false)}>キャンセル</Button>
                </Dialog.ActionTrigger>
                <Button colorPalette="red" bg="colorPalette.solid" onClick={handleResetQuiz} ml={3} loading={resetQuizLoading}>
                  リセット実行
                </Button>
              </Dialog.Footer>
              <Dialog.CloseTrigger asChild>
                <CloseButton size="sm" onClick={() => setIsResetQuizAlertOpen(false)} />
              </Dialog.CloseTrigger>
            </Dialog.Content>
          </Dialog.Positioner>
        </Portal>
      </Dialog.Root>

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
