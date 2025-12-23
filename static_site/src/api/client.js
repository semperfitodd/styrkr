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

  async getStrength() {
    return apiRequest('/strength', { method: 'GET' });
  },

  async updateStrength(strength) {
    return apiRequest('/strength', {
      method: 'PUT',
      body: JSON.stringify(strength),
    });
  },

  async getWorkouts(startDate, endDate) {
    const params = new URLSearchParams();
    if (startDate) params.append('startDate', startDate);
    if (endDate) params.append('endDate', endDate);
    const query = params.toString() ? `?${params.toString()}` : '';
    return apiRequest(`/workout${query}`, { method: 'GET' });
  },

  async logWorkout(workout) {
    return apiRequest('/workout', {
      method: 'POST',
      body: JSON.stringify(workout),
    });
  },

  async getScheduleCustomizations() {
    return apiRequest('/schedule', { method: 'GET' });
  },

  async updateScheduleCustomizations(customizations) {
    return apiRequest('/schedule', {
      method: 'PUT',
      body: JSON.stringify(customizations),
    });
  },

  // Public config endpoints (no auth)
  async getTemplate() {
    const response = await fetch(`${API_BASE_URL}/program/template`);
    if (!response.ok) {
      throw new ApiError('Failed to fetch template', 'FETCH_ERROR', response.status, null);
    }
    return response.json();
  },

  async getExercises() {
    const response = await fetch(`${API_BASE_URL}/exercises`);
    if (!response.ok) {
      throw new ApiError('Failed to fetch exercises', 'FETCH_ERROR', response.status, null);
    }
    return response.json();
  },

  // Program settings (with auth)
  async getProgramSettings() {
    return apiRequest('/program/settings', { method: 'GET' });
  },

  async saveProgramSettings(settings) {
    return apiRequest('/program/settings', {
      method: 'POST',
      body: JSON.stringify(settings),
    });
  },

  // Week renderer (with auth)
  async getWeek(weekIndex) {
    return apiRequest(`/program/week?weekIndex=${weekIndex}`, { method: 'GET' });
  },

  // Non-lifting day generator (with auth)
  async generateNonLiftDay(type, weekIndex) {
    return apiRequest(`/nonlift/day?type=${type}&weekIndex=${weekIndex}`, { method: 'GET' });
  },

};

export { ApiError };

