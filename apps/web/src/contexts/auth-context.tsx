'use client';

import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  type ReactNode,
} from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/stores/auth';
import { useApi } from '@/hooks/use-api';

interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
  avatarUrl?: string;
  organizationId: string;
  organization: {
    id: string;
    name: string;
    plan: string;
  };
}

interface AuthContextValue {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
}

interface RegisterData {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  organizationName: string;
}

const AuthContext = createContext<AuthContextValue | null>(null);

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const router = useRouter();
  const api = useApi();
  const {
    accessToken,
    refreshToken,
    setTokens,
    clearTokens,
    setUser: setStoreUser,
    user: storeUser,
  } = useAuthStore();

  const [user, setUser] = useState<User | null>(storeUser);
  const [isLoading, setIsLoading] = useState(true);

  const refreshUser = useCallback(async () => {
    if (!accessToken) {
      setUser(null);
      setIsLoading(false);
      return;
    }

    try {
      const response = await api.auth.me();
      if (response.data) {
        setUser(response.data as User);
        setStoreUser(response.data as User);
      }
    } catch (error) {
      // Token might be expired, try to refresh
      if (refreshToken) {
        try {
          const refreshResponse = await api.auth.refreshToken(refreshToken);
          if (refreshResponse.data?.accessToken) {
            setTokens(refreshResponse.data.accessToken, refreshToken);
            // Retry fetching user
            const userResponse = await api.auth.me();
            if (userResponse.data) {
              setUser(userResponse.data as User);
              setStoreUser(userResponse.data as User);
            }
          }
        } catch {
          clearTokens();
          setUser(null);
        }
      } else {
        clearTokens();
        setUser(null);
      }
    } finally {
      setIsLoading(false);
    }
  }, [accessToken, refreshToken, api, setTokens, clearTokens, setStoreUser]);

  useEffect(() => {
    refreshUser();
  }, [refreshUser]);

  const login = async (email: string, password: string) => {
    setIsLoading(true);
    try {
      const response = await api.auth.login({ email, password });
      if (response.data) {
        setTokens(response.data.accessToken, response.data.refreshToken);
        setUser(response.data.user as User);
        setStoreUser(response.data.user as User);
        router.push('/dashboard');
      }
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (data: RegisterData) => {
    setIsLoading(true);
    try {
      const response = await api.auth.register(data);
      if (response.data) {
        setTokens(response.data.accessToken, response.data.refreshToken);
        setUser(response.data.user as User);
        setStoreUser(response.data.user as User);
        router.push('/dashboard');
      }
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    try {
      await api.auth.logout();
    } catch {
      // Ignore errors on logout
    } finally {
      clearTokens();
      setUser(null);
      router.push('/auth/login');
    }
  };

  const value: AuthContextValue = {
    user,
    isLoading,
    isAuthenticated: !!user,
    login,
    register,
    logout,
    refreshUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
