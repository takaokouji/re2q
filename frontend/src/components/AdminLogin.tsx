import { useState } from 'react';
import { useMutation } from '@apollo/client';
import { ADMIN_LOGIN } from '../graphql/mutations';
import { useAuth } from '../contexts/AuthContext';
import { Box, Input, Button, Stack, Heading, Text } from '@chakra-ui/react';

export function AdminLogin() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<string[]>([]);
  const { refetch } = useAuth();

  const [adminLogin, { loading }] = useMutation(ADMIN_LOGIN);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors([]);

    try {
      const result = await adminLogin({
        variables: { username, password }
      });

      if (result.data?.adminLogin.errors.length > 0) {
        setErrors(result.data.adminLogin.errors);
      } else {
        await refetch();
      }
    } catch (err) {
      setErrors(['ログインに失敗しました']);
    }
  };

  return (
    <Box maxW="400px" mx="auto" mt="100px" p="20px">
      <Heading size="lg" mb="20px">管理者ログイン</Heading>
      <form onSubmit={handleSubmit}>
        <Stack gap="15px">
          <Box>
            <Text mb="5px">ユーザー名:</Text>
            <Input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />
          </Box>
          <Box>
            <Text mb="5px">パスワード:</Text>
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </Box>
          {errors.length > 0 && (
            <Box color="red.500">
              {errors.map((err, i) => <Text key={i}>{err}</Text>)}
            </Box>
          )}
          <Button
            type="submit"
            disabled={loading}
            colorScheme="blue"
            w="100%"
          >
            {loading ? 'ログイン中...' : 'ログイン'}
          </Button>
        </Stack>
      </form>
    </Box>
  );
}
