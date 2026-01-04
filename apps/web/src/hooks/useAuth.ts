import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth';
import type { LoginRequest, RegisterRequest } from '@horse-vision/types';

export const authKeys = {
  user: ['auth', 'user'] as const,
};

export function useCurrentUser() {
  const { isAuthenticated } = useAuthStore();

  return useQuery({
    queryKey: authKeys.user,
    queryFn: async () => {
      const response = await api.auth.me();
      return response.data;
    },
    enabled: isAuthenticated,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useLogin() {
  const router = useRouter();
  const setAuth = useAuthStore((state) => state.setAuth);

  return useMutation({
    mutationFn: async (data: LoginRequest) => {
      const response = await api.auth.login(data);
      return response.data;
    },
    onSuccess: (data) => {
      if (data) {
        setAuth({
          user: data.user,
          organization: data.organization,
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
        });
        router.push('/dashboard');
      }
    },
  });
}

export function useRegister() {
  const router = useRouter();
  const setAuth = useAuthStore((state) => state.setAuth);

  return useMutation({
    mutationFn: async (data: RegisterRequest) => {
      const response = await api.auth.register(data);
      return response.data;
    },
    onSuccess: (data) => {
      if (data) {
        setAuth({
          user: data.user,
          organization: data.organization,
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
        });
        router.push('/dashboard');
      }
    },
  });
}

export function useLogout() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const logout = useAuthStore((state) => state.logout);

  return useMutation({
    mutationFn: async () => {
      await api.auth.logout();
    },
    onSettled: () => {
      logout();
      queryClient.clear();
      router.push('/auth/login');
    },
  });
}

export function useForgotPassword() {
  return useMutation({
    mutationFn: async (email: string) => {
      const response = await api.auth.forgotPassword({ email });
      return response.data;
    },
  });
}

export function useResetPassword() {
  const router = useRouter();

  return useMutation({
    mutationFn: async (data: { token: string; password: string }) => {
      const response = await api.auth.resetPassword(data);
      return response.data;
    },
    onSuccess: () => {
      router.push('/auth/login');
    },
  });
}

export function useChangePassword() {
  return useMutation({
    mutationFn: async (data: { currentPassword: string; newPassword: string }) => {
      const response = await api.auth.changePassword(data);
      return response.data;
    },
  });
}
