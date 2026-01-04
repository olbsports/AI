'use client';

import { createApiClient } from '@horse-vision/api-client';
import { useAuthStore } from '@/stores/auth';

const apiClient = createApiClient({
  baseUrl: process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/api',
  getAccessToken: () => {
    if (typeof window === 'undefined') return null;
    return useAuthStore.getState().accessToken;
  },
  onUnauthorized: () => {
    if (typeof window !== 'undefined') {
      useAuthStore.getState().logout();
      window.location.href = '/auth/login';
    }
  },
});

export const api = apiClient;
