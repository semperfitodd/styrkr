const API_BASE_URL = process.env.REACT_APP_API_URL || '';

if (!process.env.REACT_APP_API_URL) {
  console.warn('⚠️ REACT_APP_API_URL is not set. API requests will fail.');
}

class ApiError extends Error {
  constructor(message, code, statusCode, requestId) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.statusCode = statusCode;
    this.requestId = requestId;
  }
}

async function apiRequest(endpoint, options = {}) {
  const idToken = sessionStorage.getItem('id_token');
  
  if (!idToken) {
    throw new ApiError('Not authenticated', 'UNAUTHORIZED', 401, null);
  }

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${idToken}`,
    ...options.headers,
  };

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers,
    });

    const data = await response.json();

    if (!response.ok) {
      if (data.error) {
        throw new ApiError(
          data.error.message,
          data.error.code,
          response.status,
          data.error.requestId
        );
      }
      throw new ApiError(
        'Request failed',
        'UNKNOWN_ERROR',
        response.status,
        null
      );
    }

    return data;
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    
    console.error('API request failed:', error);
    throw new ApiError(
      error.message || 'Network error',
      'NETWORK_ERROR',
      0,
      null
    );
  }
}

export const api = {
  async getProfile() {
    return apiRequest('/profile', { method: 'GET' });
  },

  async updateProfile(profile) {
    return apiRequest('/profile', {
      method: 'PUT',
      body: JSON.stringify(profile),
    });
  },

};

export { ApiError };

