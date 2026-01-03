import type { ApiResponse, ApiError } from '@horse-vision/types';

export interface ApiClientConfig {
  baseUrl: string;
  getAccessToken?: () => string | null;
  onUnauthorized?: () => void;
  onError?: (error: ApiError) => void;
}

export class ApiClient {
  private config: ApiClientConfig;

  constructor(config: ApiClientConfig) {
    this.config = config;
  }

  private getHeaders(): HeadersInit {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };

    const token = this.config.getAccessToken?.();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    return headers;
  }

  private async handleResponse<T>(response: Response): Promise<ApiResponse<T>> {
    const data: ApiResponse<T> = await response.json();

    if (!response.ok) {
      if (response.status === 401) {
        this.config.onUnauthorized?.();
      }

      if (data.error) {
        this.config.onError?.(data.error);
      }

      throw new ApiClientError(
        data.error?.message ?? 'Une erreur est survenue',
        data.error?.code ?? 'UNKNOWN_ERROR',
        response.status,
        data.error?.details
      );
    }

    return data;
  }

  async get<T>(path: string, params?: Record<string, string>): Promise<ApiResponse<T>> {
    const url = new URL(path, this.config.baseUrl);

    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        url.searchParams.append(key, value);
      });
    }

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: this.getHeaders(),
    });

    return this.handleResponse<T>(response);
  }

  async post<T>(path: string, body?: unknown): Promise<ApiResponse<T>> {
    const response = await fetch(new URL(path, this.config.baseUrl).toString(), {
      method: 'POST',
      headers: this.getHeaders(),
      body: body ? JSON.stringify(body) : undefined,
    });

    return this.handleResponse<T>(response);
  }

  async put<T>(path: string, body: unknown): Promise<ApiResponse<T>> {
    const response = await fetch(new URL(path, this.config.baseUrl).toString(), {
      method: 'PUT',
      headers: this.getHeaders(),
      body: JSON.stringify(body),
    });

    return this.handleResponse<T>(response);
  }

  async patch<T>(path: string, body: unknown): Promise<ApiResponse<T>> {
    const response = await fetch(new URL(path, this.config.baseUrl).toString(), {
      method: 'PATCH',
      headers: this.getHeaders(),
      body: JSON.stringify(body),
    });

    return this.handleResponse<T>(response);
  }

  async delete<T>(path: string): Promise<ApiResponse<T>> {
    const response = await fetch(new URL(path, this.config.baseUrl).toString(), {
      method: 'DELETE',
      headers: this.getHeaders(),
    });

    return this.handleResponse<T>(response);
  }

  async upload<T>(
    path: string,
    file: File,
    onProgress?: (progress: number) => void
  ): Promise<ApiResponse<T>> {
    const formData = new FormData();
    formData.append('file', file);

    const token = this.config.getAccessToken?.();

    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();

      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable && onProgress) {
          const progress = (event.loaded / event.total) * 100;
          onProgress(progress);
        }
      });

      xhr.addEventListener('load', () => {
        try {
          const data = JSON.parse(xhr.responseText) as ApiResponse<T>;

          if (xhr.status >= 200 && xhr.status < 300) {
            resolve(data);
          } else {
            reject(
              new ApiClientError(
                data.error?.message ?? 'Upload failed',
                data.error?.code ?? 'UPLOAD_ERROR',
                xhr.status
              )
            );
          }
        } catch {
          reject(new ApiClientError('Invalid response', 'PARSE_ERROR', xhr.status));
        }
      });

      xhr.addEventListener('error', () => {
        reject(new ApiClientError('Network error', 'NETWORK_ERROR', 0));
      });

      xhr.open('POST', new URL(path, this.config.baseUrl).toString());

      if (token) {
        xhr.setRequestHeader('Authorization', `Bearer ${token}`);
      }

      xhr.send(formData);
    });
  }
}

export class ApiClientError extends Error {
  code: string;
  status: number;
  details?: Record<string, string[]>;

  constructor(
    message: string,
    code: string,
    status: number,
    details?: Record<string, string[]>
  ) {
    super(message);
    this.name = 'ApiClientError';
    this.code = code;
    this.status = status;
    this.details = details;
  }
}
