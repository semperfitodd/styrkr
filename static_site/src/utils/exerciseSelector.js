/**
 * Exercise Selector
 * Selects random exercises from the library based on slot requirements
 */

let exerciseLibrary = null;

export async function loadExerciseLibrary() {
  if (exerciseLibrary) return exerciseLibrary;
  
  const response = await fetch('/exercises.latest.json');
  if (!response.ok) {
    throw new Error('Failed to load exercise library');
  }
  exerciseLibrary = await response.json();
  return exerciseLibrary;
}

/**
 * Map slot IDs from plan template to exercise library slot tags
 */
const slotMapping = {
  'upper_push': ['upper_push_horizontal', 'upper_push_vertical'],
  'upper_pull': ['upper_pull_vertical', 'upper_pull_horizontal'],
  'single_leg_or_core': ['single_leg_knee_dominant', 'single_leg_hip_dominant', 'core_anti_extension', 'core_anti_rotation'],
  'core_anti_extension': ['core_anti_extension'],
  'core_anti_rotation': ['core_anti_rotation'],
  'carry': ['carry'],
  'scap_stability': ['scap_stability'],
};

/**
 * Get exercises that match a slot requirement
 */
function getExercisesForSlot(library, slotId) {
  const slotTags = slotMapping[slotId] || [slotId];
  const exercises = [];
  
  for (const exercise of library.exercises) {
    for (const slotTag of slotTags) {
      if (exercise.slotTags && exercise.slotTags.includes(slotTag)) {
        exercises.push(exercise);
        break;
      }
    }
  }
  
  return exercises;
}

/**
 * Select a random exercise from a list
 */
function selectRandom(exercises) {
  if (!exercises || exercises.length === 0) return null;
  return exercises[Math.floor(Math.random() * exercises.length)];
}

/**
 * Select exercises for a workout session
 */
export async function selectExercisesForSession(session) {
  const library = await loadExerciseLibrary();
  
  const selectedExercises = {
    mainLift: session.mainLiftId,
    assistance: []
  };
  
  // Select assistance exercises
  if (session.assistanceSlots) {
    for (const slot of session.assistanceSlots) {
      const availableExercises = getExercisesForSlot(library, slot.slotId);
      const selected = selectRandom(availableExercises);
      
      if (selected) {
        selectedExercises.assistance.push({
          slotId: slot.slotId,
          exerciseId: selected.exerciseId,
          name: selected.name,
          minReps: slot.minReps,
          maxReps: slot.maxReps,
        });
      }
    }
  }
  
  return selectedExercises;
}

