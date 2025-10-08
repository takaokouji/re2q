import { useQuery } from '@apollo/client/react';
import { GET_RANKING } from '../graphql/queries';
import { Box, Heading, Text, Table, HStack, Button } from '@chakra-ui/react';

interface RankingEntry {
  playerId: string;
  playerName: string;
  correctCount: number;
  totalAnswered: number;
  rank: number;
}

interface GetRankingData {
  ranking: RankingEntry[];
}

export function RankingPanel() {
  const { data, loading, error, refetch } = useQuery<GetRankingData>(GET_RANKING);

  if (loading) return <Text>ランキングを読み込み中...</Text>;
  if (error) return <Text>エラー: {error.message}</Text>;

  return (
    <Box>
      <HStack mb="10px">
        <Heading size="md" mb="20px">ランキング</Heading>
        <Button variant="surface" onClick={() => refetch()} size="sm">更新</Button>
      </HStack>
      <Table.Root variant="outline">
        <Table.Header>
          <Table.Row>
            <Table.ColumnHeader>順位</Table.ColumnHeader>
            <Table.ColumnHeader>プレイヤー名</Table.ColumnHeader>
            <Table.ColumnHeader>正解数</Table.ColumnHeader>
            <Table.ColumnHeader>回答数</Table.ColumnHeader>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {data?.ranking.map((entry) => (
            <Table.Row key={entry.playerId}>
              <Table.Cell>{entry.rank}</Table.Cell>
              <Table.Cell>{entry.playerName}</Table.Cell>
              <Table.Cell>{entry.correctCount}</Table.Cell>
              <Table.Cell>{entry.totalAnswered}</Table.Cell>
            </Table.Row>
          ))}
        </Table.Body>
      </Table.Root>
    </Box>
  );
}
