import { useQuery } from '@apollo/client';
import { GET_RANKING } from '../graphql/queries';
import { Box, Heading, Text, Table, Thead, Tbody, Tr, Th, Td } from '@chakra-ui/react';

interface RankingEntry {
  playerUuid: string;
  correctCount: number;
  totalAnswered: number;
  rank: number;
}

interface GetRankingData {
  ranking: RankingEntry[];
}

export function RankingPanel() {
  const { data, loading, error } = useQuery<GetRankingData>(GET_RANKING, {
    pollInterval: 1000, // 1秒ごとにポーリング
  });

  if (loading) return <Text>ランキングを読み込み中...</Text>;
  if (error) return <Text>エラー: {error.message}</Text>;

  return (
    <Box>
      <Heading size="md" mb="20px">ランキング</Heading>
      <Table variant="simple">
        <Thead>
          <Tr>
            <Th>順位</Th>
            <Th>プレイヤーUUID</Th>
            <Th>正解数</Th>
            <Th>回答数</Th>
          </Tr>
        </Thead>
        <Tbody>
          {data?.ranking.map((entry) => (
            <Tr key={entry.playerUuid}>
              <Td>{entry.rank}</Td>
              <Td>{entry.playerUuid}</Td>
              <Td>{entry.correctCount}</Td>
              <Td>{entry.totalAnswered}</Td>
            </Tr>
          ))}
        </Tbody>
      </Table>
    </Box>
  );
}
