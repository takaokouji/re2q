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

  if (error) return <Text>エラー: {error.message}</Text>;

  const ranking = data?.ranking;

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
          {ranking?.map((entry) => (
            <Table.Row key={entry.playerId}>
              <Table.Cell>{entry.rank}</Table.Cell>
              <Table.Cell>{entry.playerName}</Table.Cell>
              <Table.Cell>{entry.correctCount}</Table.Cell>
              <Table.Cell>{entry.totalAnswered}</Table.Cell>
              <Table.Cell>{entry.lotteryScore === 1 ? '🎉' : ''}</Table.Cell>
            </Table.Row>
          ))}
        </Table.Body>
      </Table.Root>
    </Box>
  );
};
