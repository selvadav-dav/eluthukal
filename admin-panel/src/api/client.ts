/**
 * Axios API Client with JWT Bearer Interceptor
 */
import axios from 'axios';

export const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://eluthukkal-api.macvelsoftware.com/api/v1';
export const MEDIA_BASE_URL = import.meta.env.VITE_MEDIA_BASE_URL || 'https://eluthukkal-api.macvelsoftware.com';

export const resolveMediaUrl = (path?: string | null) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  const clean = path.startsWith('/') ? path.slice(1) : path;
  return `${MEDIA_BASE_URL}/${clean}`;
};

/**
 * Resolves video URLs to stream via the backend subdomain proxy
 * completely hiding the Cloudinary URL from browser elements/DevTools.
 */
export const resolveVideoProxyUrl = (urlOrPath?: string | null, videoId?: string | number) => {
  if (!urlOrPath && !videoId) return '';
  if (videoId) {
    return `${API_BASE_URL}/videos/${videoId}/stream`;
  }
  if (urlOrPath) {
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      if (urlOrPath.includes('cloudinary.com')) {
        return `${API_BASE_URL}/videos/stream/proxy?url=${encodeURIComponent(urlOrPath)}`;
      }
      return urlOrPath;
    }
    const clean = urlOrPath.startsWith('/') ? urlOrPath.slice(1) : urlOrPath;
    return `${MEDIA_BASE_URL}/${clean}`;
  }
  return '';
};

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor: Attach Bearer token from localStorage
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('agaram_admin_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    // Let the browser set the Content-Type with multipart boundary when sending FormData
    if (config.data instanceof FormData && config.headers) {
      delete config.headers['Content-Type'];
    }

    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: Handle 401 Unauthorized
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Clear token and redirect to login if not already there
      localStorage.removeItem('agaram_admin_token');
      localStorage.removeItem('agaram_admin_user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);
