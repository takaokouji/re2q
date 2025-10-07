import { useState } from 'react';
import {
  Box,
  Button,
  Container,
  Heading,
  Stack,
  Text,
  VStack,
  Badge,
  HStack,
} from '@chakra-ui/react';
import { css, keyframes } from '@emotion/react';
import React from 'react';

interface Answer {
  id: string;
  playerId: string;
  questionId: string;
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
  activeQuestionId: string | null;
  questionStartedAt: string | null;
  questionEndsAt: string | null;
  durationSeconds: number | null;
  questionActive: boolean;
  remainingSeconds: number;
  activeQuestion: {
    id: string;
    questionNumber: number;
  } | null;
}

interface AnswerScreenProps {
  quizState: QuizState | null;
  answers: Answer[];
  onSubmitAnswer: (answer: boolean) => Promise<void>;
  loading?: boolean;
}

// パルスアニメーション定義
const pulse = keyframes`
  0%, 100% { opacity: 1; }
  50% { opacity: 0.85; }
`;

export const AnswerScreen: React.FC<AnswerScreenProps> = ({
  quizState,
  answers,
  onSubmitAnswer,
  loading = false,
}) => {
  const [submitting, setSubmitting] = useState(false);
  const [lastSubmittedAnswer, setLastSubmittedAnswer] = useState<boolean | null>(null);

  const handleSubmit = async (answer: boolean) => {
    if (submitting || loading || !quizState) return;

    setSubmitting(true);
    setLastSubmittedAnswer(answer);

    try {
      await onSubmitAnswer(answer);
    } catch (error) {
      console.error('Failed to submit answer:', error);
    } finally {
      setSubmitting(false);
    }
  };

  // 現在の問題に対して既に回答済みかどうか
  const hasAnsweredCurrentQuestion = quizState?.activeQuestionId
    ? answers.some(a => a.questionId === quizState.activeQuestionId)
    : false;

  // ボタンの無効化判定（通信中以外は回答可能）
  const isButtonDisabled = loading || !quizState || submitting;

  // ステータスメッセージ
  const getStatusMessage = () => {
    if (loading) return 'データを読み込み中...';
    if (!quizState) return 'クイズ情報を取得中...';
    if (submitting) return '送信中...';
    if (!quizState.quizActive) return 'しばらくお待ち下さい\n出題されたら回答してください！';
    if (!quizState.activeQuestion) return 'しばらくお待ち下さい\n次の問題が出題されたら回答してください！';
    if (hasAnsweredCurrentQuestion) return `第${quizState.activeQuestion.questionNumber}問に回答済み\n次の問題が出題されたら回答してください！`;
    return `第${quizState.activeQuestion.questionNumber}問\n回答してください！`;
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
        <Heading size="md" mb={0}>{ "{ re2q }" }</Heading>
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
        {quizState?.activeQuestion && (
          <HStack justify="center" mt={2}>
            <Badge colorScheme="blue" fontSize="md" px={3} py={1}>
              問題 {quizState.activeQuestion.questionNumber}
            </Badge>
            {hasAnsweredCurrentQuestion && (
              <Badge colorScheme="green" fontSize="md" px={3} py={1}>
                回答済み
              </Badge>
            )}
            {quizState.remainingSeconds > 0 && (
              <Badge colorScheme="orange" fontSize="md" px={3} py={1}>
                残り {quizState.remainingSeconds}秒
              </Badge>
            )}
          </HStack>
        )}
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
            css={
              quizState?.questionActive && !hasAnsweredCurrentQuestion && !submitting
                ? css`
                    animation: ${pulse} 2s ease-in-out infinite;
                  `
                : undefined
            }
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
            css={
              quizState?.questionActive && !hasAnsweredCurrentQuestion && !submitting
                ? css`
                    animation: ${pulse} 2s ease-in-out infinite;
                  `
                : undefined
            }
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
