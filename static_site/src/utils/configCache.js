import { api } from '../api/client';

const CACHE_KEY_PREFIX = 'styrkr_config_';
const CACHE_DURATION = 10 * 60 * 1000; // 10 minutes

/**
 * Get config from cache or fetch from API
 */
async function getCachedConfig(key, fetchFn) {
  const cacheKey = `${CACHE_KEY_PREFIX}${key}`;
  const timestampKey = `${cacheKey}_timestamp`;
  
  try {
    // Check cache
    const cached = localStorage.getItem(cacheKey);
    const timestamp = localStorage.getItem(timestampKey);
    
    if (cached && timestamp) {
      const age = Date.now() - parseInt(timestamp, 10);
      if (age < CACHE_DURATION) {
        return JSON.parse(cached);
      }
    }
  } catch (error) {
    console.warn(`Failed to read ${key} from cache:`, error);
  }
  
  // Fetch fresh data
  const data = await fetchFn();
  
  // Update cache
  try {
    localStorage.setItem(cacheKey, JSON.stringify(data));
    localStorage.setItem(timestampKey, Date.now().toString());
  } catch (error) {
    console.warn(`Failed to cache ${key}:`, error);
  }
  
  return data;
}

/**
 * Get program template from cache or API
 */
export async function getTemplate() {
  return getCachedConfig('template', () => api.getTemplate());
}

/**
 * Get exercise library from cache or API
 */
export async function getExercises() {
  return getCachedConfig('exercises', () => api.getExercises());
}

/**
 * Clear all config caches
 */
export function clearConfigCache() {
  const keys = Object.keys(localStorage);
  keys.forEach(key => {
    if (key.startsWith(CACHE_KEY_PREFIX)) {
      localStorage.removeItem(key);
    }
  });
}

/**
 * Preload configs on app start
 */
export async function preloadConfigs() {
  try {
    await Promise.all([
      getTemplate(),
      getExercises()
    ]);
    console.log('✅ Configs preloaded');
  } catch (error) {
    console.error('Failed to preload configs:', error);
  }
}

