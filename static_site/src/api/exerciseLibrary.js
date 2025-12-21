// Exercise Library API Client
// Fetches from CloudFront (no auth required)

const LIBRARY_URL = process.env.REACT_APP_LIBRARY_URL || 'https://dev.styrkr.com/config/exercises.latest.json';

let cachedLibrary = null;
let cacheTimestamp = null;
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

export class ExerciseLibraryError extends Error {
  constructor(message, code) {
    super(message);
    this.name = 'ExerciseLibraryError';
    this.code = code;
  }
}

/**
 * Fetch the exercise library from CloudFront
 * Uses in-memory caching to avoid repeated fetches
 */
export async function fetchExerciseLibrary(forceRefresh = false) {
  const now = Date.now();
  
  // Return cached version if valid
  if (!forceRefresh && cachedLibrary && cacheTimestamp && (now - cacheTimestamp < CACHE_DURATION)) {
    return cachedLibrary;
  }

  try {
    const response = await fetch(LIBRARY_URL, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
      // Add cache-busting parameter if force refresh
      ...(forceRefresh ? { cache: 'reload' } : {}),
    });

    if (!response.ok) {
      throw new ExerciseLibraryError(
        `Failed to fetch exercise library: ${response.statusText}`,
        'FETCH_ERROR'
      );
    }

    const library = await response.json();
    
    // Validate library structure
    if (!library.exercises || !Array.isArray(library.exercises)) {
      throw new ExerciseLibraryError(
        'Invalid library structure: missing exercises array',
        'INVALID_STRUCTURE'
      );
    }

    // Cache the result
    cachedLibrary = library;
    cacheTimestamp = now;

    return library;
  } catch (error) {
    if (error instanceof ExerciseLibraryError) {
      throw error;
    }
    
    console.error('Failed to fetch exercise library:', error);
    throw new ExerciseLibraryError(
      error.message || 'Network error',
      'NETWORK_ERROR'
    );
  }
}

/**
 * Filter exercises by category
 */
export function filterByCategory(exercises, category) {
  return exercises.filter(ex => ex.category === category);
}

/**
 * Filter exercises by slot tags
 */
export function filterBySlotTags(exercises, slotTags) {
  const tags = Array.isArray(slotTags) ? slotTags : [slotTags];
  return exercises.filter(ex => 
    ex.slotTags.some(tag => tags.includes(tag))
  );
}

/**
 * Filter exercises by equipment
 */
export function filterByEquipment(exercises, equipment) {
  const equipmentList = Array.isArray(equipment) ? equipment : [equipment];
  return exercises.filter(ex =>
    ex.equipment.some(eq => equipmentList.includes(eq))
  );
}

/**
 * Filter exercises that are safe for user constraints
 * Returns exercises where NONE of the user's constraints are in constraintsBlocked
 */
export function filterByConstraints(exercises, userConstraints) {
  if (!userConstraints || userConstraints.length === 0) {
    return exercises;
  }
  
  return exercises.filter(ex => {
    // Exercise is safe if none of its blocked constraints match user constraints
    return !ex.constraintsBlocked.some(blocked => userConstraints.includes(blocked));
  });
}

/**
 * Search exercises by name or notes
 */
export function searchExercises(exercises, query) {
  const lowerQuery = query.toLowerCase();
  return exercises.filter(ex =>
    ex.name.toLowerCase().includes(lowerQuery) ||
    ex.notes.toLowerCase().includes(lowerQuery)
  );
}

/**
 * Group exercises by category
 */
export function groupByCategory(exercises) {
  return exercises.reduce((acc, ex) => {
    if (!acc[ex.category]) {
      acc[ex.category] = [];
    }
    acc[ex.category].push(ex);
    return acc;
  }, {});
}

/**
 * Get exercises for a specific slot
 */
export function getExercisesForSlot(library, slotTag, userConstraints = []) {
  let exercises = filterBySlotTags(library.exercises, slotTag);
  exercises = filterByConstraints(exercises, userConstraints);
  return exercises;
}

/**
 * Get all main lifts
 */
export function getMainLifts(library) {
  return filterByCategory(library.exercises, 'main');
}

/**
 * Get all accessories
 */
export function getAccessories(library) {
  return filterByCategory(library.exercises, 'accessory');
}

/**
 * Get all conditioning exercises
 */
export function getConditioning(library) {
  return filterByCategory(library.exercises, 'conditioning');
}

/**
 * Get all mobility exercises
 */
export function getMobility(library) {
  return filterByCategory(library.exercises, 'mobility');
}

/**
 * Clear the cache (useful for testing or force refresh)
 */
export function clearCache() {
  cachedLibrary = null;
  cacheTimestamp = null;
}


