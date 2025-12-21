const LIBRARY_URL = process.env.REACT_APP_LIBRARY_URL || 'https://dev.styrkr.com/config/exercises.latest.json';

let cachedLibrary = null;
let cacheTimestamp = null;
const CACHE_DURATION = 5 * 60 * 1000;

export class ExerciseLibraryError extends Error {
  constructor(message, code) {
    super(message);
    this.name = 'ExerciseLibraryError';
    this.code = code;
  }
}

export async function fetchExerciseLibrary(forceRefresh = false) {
  const now = Date.now();
  
  if (!forceRefresh && cachedLibrary && cacheTimestamp && (now - cacheTimestamp < CACHE_DURATION)) {
    return cachedLibrary;
  }

  try {
    const response = await fetch(LIBRARY_URL, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
      ...(forceRefresh ? { cache: 'reload' } : {}),
    });

    if (!response.ok) {
      throw new ExerciseLibraryError(
        `Failed to fetch exercise library: ${response.statusText}`,
        'FETCH_ERROR'
      );
    }

    const library = await response.json();
    
    if (!library.exercises || !Array.isArray(library.exercises)) {
      throw new ExerciseLibraryError(
        'Invalid library structure: missing exercises array',
        'INVALID_STRUCTURE'
      );
    }

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

export function filterByCategory(exercises, category) {
  return exercises.filter(ex => ex.category === category);
}

export function filterBySlotTags(exercises, slotTags) {
  const tags = Array.isArray(slotTags) ? slotTags : [slotTags];
  return exercises.filter(ex => 
    ex.slotTags.some(tag => tags.includes(tag))
  );
}

export function filterByEquipment(exercises, equipment) {
  const equipmentList = Array.isArray(equipment) ? equipment : [equipment];
  return exercises.filter(ex =>
    ex.equipment.some(eq => equipmentList.includes(eq))
  );
}

export function filterByConstraints(exercises, userConstraints) {
  if (!userConstraints || userConstraints.length === 0) {
    return exercises;
  }
  
  return exercises.filter(ex => {
    // Exercise is safe if none of its blocked constraints match user constraints
    return !ex.constraintsBlocked.some(blocked => userConstraints.includes(blocked));
  });
}

export function searchExercises(exercises, query) {
  const lowerQuery = query.toLowerCase();
  return exercises.filter(ex =>
    ex.name.toLowerCase().includes(lowerQuery) ||
    ex.notes.toLowerCase().includes(lowerQuery)
  );
}

export function groupByCategory(exercises) {
  return exercises.reduce((acc, ex) => {
    if (!acc[ex.category]) {
      acc[ex.category] = [];
    }
    acc[ex.category].push(ex);
    return acc;
  }, {});
}

export function getExercisesForSlot(library, slotTag, userConstraints = []) {
  let exercises = filterBySlotTags(library.exercises, slotTag);
  exercises = filterByConstraints(exercises, userConstraints);
  return exercises;
}

export function getMainLifts(library) {
  return filterByCategory(library.exercises, 'main');
}

export function getAccessories(library) {
  return filterByCategory(library.exercises, 'accessory');
}

export function getSupplemental(library) {
  return filterByCategory(library.exercises, 'supplemental');
}

export function getConditioning(library) {
  return filterByCategory(library.exercises, 'conditioning');
}

export function getMobility(library) {
  return filterByCategory(library.exercises, 'mobility');
}

export function clearCache() {
  cachedLibrary = null;
  cacheTimestamp = null;
}


