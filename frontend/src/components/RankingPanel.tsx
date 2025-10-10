import { useState } from 'react';
import { useQuery } from '@apollo/client/react';
import { GET_RANKING } from '../graphql/queries';
import { Box, Heading, Text, Table, HStack, Button } from '@chakra-ui/react';

interface RankingEntry {
  playerId: string;
  playerName: string;
  correctCount: number;
  totalAnswered: number;
  rank: number;
  lotteryScore?: number;
}

interface GetRankingData {
  ranking: RankingEntry[];
}

interface RankingPanelProps {
  lottery?: boolean;
}

export const RankingPanel: React.FC<RankingPanelProps> = ({
  lottery = false
}) => {
  const { data, loading, error, refetch } = useQuery<GetRankingData>(GET_RANKING, {
    variables: { lottery }
  });

  // 上位5名の名前の表示状態を管理
  const [revealedPlayers, setRevealedPlayers] = useState<Set<string>>(new Set());

  if (error) return <Text>エラー: {error.message}</Text>;

  const ranking = data?.ranking;

  // プレイヤー名の表示切り替え
  const togglePlayerName = (playerId: string) => {
    setRevealedPlayers((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(playerId)) {
        newSet.delete(playerId);
      } else {
        newSet.add(playerId);
      }
      return newSet;
    });
  };

  // 順位に応じた色を取得
  const getRankColor = (rank: number) => {
    switch (rank) {
      case 1:
        return 'gold';
      case 2:
        return 'silver';
      case 3:
        return '#CD7F32'; // ブロンズ
      case 4:
      case 5:
        return 'blue.400';
      default:
        return 'inherit';
    }
  };

  return (
    <Box>
      <HStack mb="20px" justifyContent="center">
        <Heading size="md" mb={0}>ランキング</Heading>
        <Button variant="surface" onClick={() => refetch()} size="xs" loading={loading}>更新</Button>
      </HStack>
      <Table.Root variant="outline">
        <Table.Header>
          <Table.Row>
            <Table.ColumnHeader>順位</Table.ColumnHeader>
            <Table.ColumnHeader>プレイヤー名</Table.ColumnHeader>
            <Table.ColumnHeader>正解数</Table.ColumnHeader>
            <Table.ColumnHeader>回答数</Table.ColumnHeader>
            <Table.ColumnHeader>抽選結果</Table.ColumnHeader>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {ranking?.map((entry) => {
            const isTopFive = lottery && entry.rank <= 5;
            const isRevealed = revealedPlayers.has(entry.playerId);
            const rankColor = getRankColor(entry.rank);

            return (
              <Table.Row key={entry.playerId}>
                <Table.Cell>{entry.rank}</Table.Cell>
                <Table.Cell>
                  {isTopFive ? (
                    <Text
                      as="span"
                      cursor="pointer"
                      onClick={() => togglePlayerName(entry.playerId)}
                      color={isRevealed ? rankColor : 'inherit'}
                      fontSize={isRevealed ? '2xl' : 'md'}
                      fontWeight={isRevealed ? 'bold' : 'normal'}
                      textShadow="0 0 2px gray"
                      transition="all 0.3s ease"
                      _hover={{ opacity: 0.7 }}
                    >
                      {isRevealed ? entry.playerName : '??????'}
                    </Text>
                  ) : (
                    entry.playerName
                  )}
                </Table.Cell>
                <Table.Cell>{entry.correctCount}</Table.Cell>
                <Table.Cell>{entry.totalAnswered}</Table.Cell>
                <Table.Cell>{entry.lotteryScore}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table.Root>
    </Box>
  );
};
