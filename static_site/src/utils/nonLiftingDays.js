import {
  generateGPPWorkout,
  generateMobilityWorkout,
  generateActiveRecoveryWorkout,
  generatePilatesWorkout,
} from './workoutGenerator';

export const DAY_TYPES = {
  MAIN: 'main',
  GPP: 'gpp',
  MOBILITY: 'mobility',
  PILATES: 'pilates',
  REST: 'rest',
};

export async function generateWorkoutForType(type, userProfile = {}, programContext = {}) {
  const options = {
    conditioningLevel: userProfile.conditioningLevel || 'moderate',
    constraints: userProfile.constraints || [],
    equipment: userProfile.equipment || ['bike', 'rower', 'jumprope', 'kb', 'db', 'medball'],
    weekPhase: programContext.weekPhase || 'LEADER',
    nextSession: programContext.nextSession || null,
    durationTarget: 30,
  };

  switch (type) {
    case DAY_TYPES.GPP:
      return await generateGPPWorkout(options);
    case DAY_TYPES.MOBILITY:
      return await generateMobilityWorkout(options);
    case DAY_TYPES.PILATES:
      return generatePilatesWorkout();
    case DAY_TYPES.REST:
      return await generateActiveRecoveryWorkout(options);
    default:
      return null;
  }
}

export function getDefaultDayAssignments(trainingDaysPerWeek, preferredNonLiftingMode = 'gpp') {
  const assignments = {
    1: { type: DAY_TYPES.MAIN, index: 0 },
    2: { type: DAY_TYPES.MAIN, index: 1 },
    4: { type: DAY_TYPES.MAIN, index: 2 },
    5: { type: DAY_TYPES.MAIN, index: 3 },
  };

  const nonLiftingType = preferredNonLiftingMode || 'gpp';

  if (trainingDaysPerWeek >= 5) {
    assignments[3] = { type: nonLiftingType };
  }
  
  if (trainingDaysPerWeek >= 6) {
    assignments[6] = { type: nonLiftingType };
  }
  
  if (trainingDaysPerWeek >= 7) {
    assignments[0] = { type: nonLiftingType };
  }

  return assignments;
}
