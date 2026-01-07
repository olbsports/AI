'use client';

import { createContext, useContext, useMemo, type ReactNode } from 'react';
import { createApiClient, type HorseTempoApi } from '@horse-vision/api-client';
import { useAuthStore } from '@/stores/auth';

const ApiContext = createContext<HorseTempoApi | null>(null);

interface ApiProviderProps {
  children: ReactNode;
}

export function ApiProvider({ children }: ApiProviderProps) {
  const { accessToken, logout } = useAuthStore();

  const api = useMemo(() => {
    return createApiClient({
      baseUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
      getAccessToken: () => accessToken,
      onUnauthorized: () => {
        logout();
        window.location.href = '/auth/login';
      },
    });
  }, [accessToken, logout]);

  return <ApiContext.Provider value={api}>{children}</ApiContext.Provider>;
}

export function useApi(): HorseTempoApi {
  const context = useContext(ApiContext);
  if (!context) {
    throw new Error('useApi must be used within an ApiProvider');
  }
  return context;
}
