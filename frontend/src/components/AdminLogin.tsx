import { useState } from 'react';
import { useMutation } from '@apollo/client/react';
import { ADMIN_LOGIN } from '../graphql/mutations';
import { useAuth } from '../contexts/AuthContext';
import { Box, Input, Button, Stack, Heading, Text } from '@chakra-ui/react';

interface AdminLoginMutation {
  adminLogin: {
    admin: {
      id: string;
      username: string;
    } | null;
    errors: string[];
  };
}

export function AdminLogin() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<string[]>([]);
  const { refetch } = useAuth();

  const [adminLogin, { loading }] = useMutation<AdminLoginMutation>(ADMIN_LOGIN);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors([]);

    try {
      const { data }  = await adminLogin({
        variables: { username, password }
      });

      if (data?.adminLogin?.errors && data?.adminLogin?.errors?.length > 0) {
        setErrors(data.adminLogin.errors);
      } else {
        await refetch();
      }
    } catch (error) {
      console.error("Login failed:", error);
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
            colorPalette="blue"
            bg="colorPalette.solid"
            w="100%"
          >
            {loading ? 'ログイン中...' : 'ログイン'}
          </Button>
        </Stack>
      </form>
    </Box>
  );
}
