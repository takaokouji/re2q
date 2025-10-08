import { createContext, useContext } from 'react';
import type { ReactNode } from 'react';
import { useQuery } from '@apollo/client/react';
import { gql } from '@apollo/client';

const GET_CURRENT_ADMIN = gql`
  query GetCurrentAdmin {
    currentAdmin {
      id
      username
    }
  }
`;

interface Admin {
  id: string;
  username: string;
}

interface AuthContextType {
  admin: Admin | null;
  loading: boolean;
  refetch: () => void;
}

interface CurrentAdmin {
  currentAdmin: Admin | null;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { data, loading, refetch } = useQuery<CurrentAdmin>(GET_CURRENT_ADMIN);

  return (
    <AuthContext.Provider value={{ admin: data?.currentAdmin || null, loading, refetch }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
