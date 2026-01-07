import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { User, Organization } from '@horse-tempo/types';

interface AuthState {
  user: User | null;
  organization: Organization | null;
  accessToken: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;

  setAuth: (data: {
    user: User;
    organization: Organization;
    accessToken: string;
    refreshToken: string;
  }) => void;

  updateUser: (user: Partial<User>) => void;
  updateTokens: (accessToken: string, refreshToken?: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      organization: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,

      setAuth: ({ user, organization, accessToken, refreshToken }) =>
        set({
          user,
          organization,
          accessToken,
          refreshToken,
          isAuthenticated: true,
        }),

      updateUser: (userData) =>
        set((state) => ({
          user: state.user ? { ...state.user, ...userData } : null,
        })),

      updateTokens: (accessToken, refreshToken) =>
        set((state) => ({
          accessToken,
          refreshToken: refreshToken ?? state.refreshToken,
        })),

      logout: () =>
        set({
          user: null,
          organization: null,
          accessToken: null,
          refreshToken: null,
          isAuthenticated: false,
        }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
      }),
    }
  )
);
