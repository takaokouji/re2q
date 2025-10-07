import { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Container,
  Heading,
  Stack,
  Text,
  VStack,
  HStack,
} from '@chakra-ui/react';
import React from 'react';

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

interface AnswerScreenProps {
  me: Player | null;
  quizState: QuizState | null;
  answers: Answer[];
  onSubmitAnswer: (answer: boolean) => Promise<void>;
  onCooldownEnd: () => Promise<void>;
  loading?: boolean;
}


export const AnswerScreen: React.FC<AnswerScreenProps> = ({
  me,
  quizState,
  answers,
  onSubmitAnswer,
  onCooldownEnd,
  loading = false,
}) => {
  const [submitting, setSubmitting] = useState(false);
  const [lastSubmittedAnswer, setLastSubmittedAnswer] = useState<boolean | null>(null);
  const [cooldownRemaining, setCooldownRemaining] = useState(0);

  // クールダウンタイマー
  useEffect(() => {
    if (cooldownRemaining > 0) {
      const timer = setTimeout(() => {
        setCooldownRemaining(cooldownRemaining - 1);
      }, 1000);
      return () => clearTimeout(timer);
    } else if (cooldownRemaining === 0 && lastSubmittedAnswer !== null && !submitting) {
      // クールダウン終了時にクイズ状態を再取得
      onCooldownEnd();
      setLastSubmittedAnswer(null);
    }
  }, [cooldownRemaining, lastSubmittedAnswer, onCooldownEnd, submitting]);

  const handleSubmit = async (answer: boolean) => {
    if (submitting || loading || !quizState || cooldownRemaining > 0) return;

    setSubmitting(true);
    setLastSubmittedAnswer(answer);

    try {
      await onSubmitAnswer(answer);
    } catch (error) {
      console.error('Failed to submit answer:', error);
    } finally {
      setCooldownRemaining(3); // 成功・失敗に関わらず3秒間のクールダウンを設定
      setSubmitting(false);
    }
  };

  console.log('Rendering AnswerScreen with quizState:', quizState);
  console.log('Answers:', answers);

  // 現在の問題に対して既に回答済みかどうか
  const hasAnsweredCurrentQuestion = quizState?.question
    ? answers.some(a => a.question.id === quizState.question?.id)
    : false;

  // ボタンの無効化判定（通信中、クールダウン中は回答不可）
  const isButtonDisabled = loading || !quizState || submitting || cooldownRemaining > 0;

  // ステータスメッセージ
  const getStatusMessage = () => {
    if (loading) return 'データを読み込み中...';
    if (!quizState) return 'クイズ情報を取得中...';
    if (submitting) return '回答中...';
    if (cooldownRemaining > 0) return `お待ち下さい\n${cooldownRemaining}秒...`;
    if (!quizState.quizActive) return 'クイズ開始までお待ち下さい\n開始されたら回答してください！';
    if (!quizState.questionActive) return '出題までお待ち下さい\n出題されたら回答してください！';
    if (hasAnsweredCurrentQuestion) return `第${quizState.question?.questionNumber}問に回答済み。次が\n出題されたら回答してください！`;
    return `第${quizState.question?.questionNumber}問に回答してください！`;
  };

  return (
    <Box minH="100vh" width="84vw" bg="gray.50" display="flex" flexDirection="column">
      {/* ヘッダー */}
      <Box
        bg="blue.500"
        color="white"
        py={4}
        px={6}
        boxShadow="md"
        cursor="pointer"
        onClick={() => window.open('https://github.com/takaokouji/re2q/', '_blank', 'noopener,noreferrer')}
        _hover={{ bg: 'blue.600' }}
        transition="background-color 0.2s"
      >
        <Heading size="md" mb={0}>{ `【ID:${me?.name}】` }</Heading>
      </Box>

      {/* 情報表示 */}
      <Box height="12vh" py={6} px={6} textAlign="center" bg="white" boxShadow="sm">
        <Text fontSize="md" fontWeight="bold" color="gray.700">
          {getStatusMessage().split('\n').map((line, index) => (
            <React.Fragment key={index}>
              {line}
              <br />
            </React.Fragment>
          ))}
        </Text>
      </Box>

      {/* 回答ボタン */}
      <Container maxW="container.sm" px={6} py={8}>
        <Stack direction="column" gap={4}>
          <Button
            size="lg"
            height="120px"
            fontSize="6xl"
            colorPalette="green"
            bg="colorPalette.solid"
            color="white"
            borderRadius="xl"
            boxShadow="lg"
            disabled={isButtonDisabled}
            onClick={() => handleSubmit(true)}
            _active={{ transform: 'scale(0.98)' }}
            _hover={{ transform: isButtonDisabled ? 'none' : 'scale(1.02)' }}
            _disabled={{ opacity: 0.4, cursor: 'not-allowed' }}
            transition="all 0.2s"
            aria-label="正解と回答"
            aria-pressed={lastSubmittedAnswer === true && submitting}
            position="relative"
            overflow="hidden"
          >
            ◯
          </Button>

          <Button
            size="lg"
            height="120px"
            fontSize="6xl"
            colorPalette="red"
            bg="colorPalette.solid"
            color="white"
            borderRadius="xl"
            boxShadow="lg"
            disabled={isButtonDisabled}
            onClick={() => handleSubmit(false)}
            _active={{ transform: 'scale(0.98)' }}
            _hover={{ transform: isButtonDisabled ? 'none' : 'scale(1.02)' }}
            _disabled={{ opacity: 0.4, cursor: 'not-allowed' }}
            transition="all 0.2s"
            aria-label="不正解と回答"
            aria-pressed={lastSubmittedAnswer === false && submitting}
            position="relative"
            overflow="hidden"
          >
            ✗
          </Button>
        </Stack>
      </Container>

      {/* 回答履歴 */}
      <Box flex={1} px={6} py={4} overflowY="auto">
        <Heading size="sm" mb={3} color="gray.700">
          回答履歴
        </Heading>
        {answers.length === 0 ? (
          <Text color="gray.500" textAlign="center" py={8}>
            まだ回答がありません
          </Text>
        ) : (
          <VStack gap={2} align="stretch">
            {[...answers].reverse().map((answer) => (
              <Box
                key={answer.id}
                p={4}
                bg="white"
                borderRadius="md"
                boxShadow="sm"
                borderLeft="4px solid"
                borderColor={answer.playerAnswer ? 'green.400' : 'red.400'}
              >
                <HStack justify="space-between">
                  <HStack gap={3}>
                    <Text fontSize="2xl" fontWeight="bold">
                      {answer.playerAnswer ? '◯' : '✗'}
                    </Text>
                    <Text fontSize="md" fontWeight="semibold" color="gray.700">
                      第{answer.question.questionNumber}問
                    </Text>
                  </HStack>
                  <Text fontSize="xs" color="gray.500">
                    {new Date(answer.answeredAt).toLocaleTimeString('ja-JP')}
                  </Text>
                </HStack>
              </Box>
            ))}
          </VStack>
        )}
      </Box>
    </Box>
  );
};
