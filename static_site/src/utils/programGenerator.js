/**
 * Program Generator for 5/3/1 Krypteia
 * Generates a 13-week training program based on user's training maxes
 */

/**
 * Round weight according to rounding rules
 */
function roundWeight(weight, units) {
  const increment = units === 'lb' ? 5 : 2.5;
  return Math.round(weight / increment) * increment;
}

/**
 * Calculate weight for a set based on TM and percentage
 */
function calculateSetWeight(tm, pctTM, units) {
  const rawWeight = tm * pctTM;
  return roundWeight(rawWeight, units);
}

/**
 * Generate sets for a given scheme and training max
 */
function generateSets(scheme, tm, units) {
  return scheme.workSets.map(set => ({
    weight: calculateSetWeight(tm, set.pctTM, units),
    targetReps: set.reps,
    pctTM: set.pctTM,
  }));
}

/**
 * Get the set scheme for a given week in the cycle
 */
function getSetSchemeForWeek(template, phase, weekInCycle) {
  if (phase.mainLiftScheme) {
    return template.setSchemes[phase.mainLiftScheme];
  }
  
  if (phase.mainLiftSchemeByWeekInCycle) {
    const weekInPhase = ((weekInCycle - 1) % 3) + 1;
    const schemeName = phase.mainLiftSchemeByWeekInCycle[weekInPhase.toString()];
    return template.setSchemes[schemeName];
  }
  
  return null;
}

/**
 * Generate a single session for a given week
 */
function generateSession(template, sessionTemplate, phase, weekInCycle, trainingMaxes, units) {
  const liftId = sessionTemplate.mainLiftId;
  const tm = trainingMaxes[liftId];
  
  const setScheme = getSetSchemeForWeek(template, phase, weekInCycle);
  
  if (!setScheme) {
    // Test week or special week - return minimal structure
    return {
      sessionId: sessionTemplate.sessionId,
      label: sessionTemplate.label,
      mainLiftId: liftId,
      phase: phase.phaseId,
      isTestWeek: phase.phaseId === 'TEST',
      isReset: phase.phaseId === 'RESET',
    };
  }
  
  const mainSets = generateSets(setScheme, tm, units);
  
  // Generate supplemental (FSL) if enabled
  let supplemental = null;
  if (phase.rules?.supplementalUsesFSL && phase.rules?.supplementalEnabled !== false) {
    // FSL uses the FIRST set weight of the current week's scheme
    const firstSetPercent = setScheme.workSets[0].pctTM;
    const fslWeight = calculateSetWeight(tm, firstSetPercent, units);
    const fslTemplate = sessionTemplate.supplemental?.find(s => s.type === 'fsl_main_lift');
    if (fslTemplate) {
      supplemental = {
        type: 'fsl_main_lift',
        label: fslTemplate.label,
        sets: fslTemplate.sets,
        repsRange: fslTemplate.repsRange,
        weight: fslWeight,
      };
    }
  }
  
  return {
    sessionId: sessionTemplate.sessionId,
    label: sessionTemplate.label,
    mainLiftId: liftId,
    phase: phase.phaseId,
    setScheme: setScheme.label,
    mainSets,
    supplemental,
    assistanceSlots: sessionTemplate.assistanceSlots,
    circuit: {
      ...sessionTemplate.circuit,
      rounds: phase.rules?.circuitRounds || sessionTemplate.circuit?.rounds || 5,
    },
    conditioningSlots: sessionTemplate.conditioningSlots,
    mobilitySlots: sessionTemplate.mobilitySlots,
    rules: phase.rules,
  };
}

/**
 * Generate a single week of training
 */
function generateWeek(template, weekNumber, trainingMaxes, units) {
  // Find which phase this week belongs to
  const phase = template.macrocycle.phases.find(p => p.weeks.includes(weekNumber));
  
  if (!phase) {
    throw new Error(`Week ${weekNumber} not found in any phase`);
  }
  
  const sessions = template.macrocycle.weeklySessions.map(sessionSlot => {
    const sessionTemplate = template.sessionTemplates[sessionSlot.sessionTemplateRef];
    return generateSession(template, sessionTemplate, phase, weekNumber, trainingMaxes, units);
  });
  
  return {
    weekNumber,
    phase: phase.phaseId,
    phaseLabel: phase.label,
    sessions,
  };
}

/**
 * Generate the full 13-week program
 */
export function generateProgram(template, trainingMaxes, units) {
  const weeks = [];
  
  for (let weekNum = 1; weekNum <= template.macrocycle.cycleLengthWeeks; weekNum++) {
    weeks.push(generateWeek(template, weekNum, trainingMaxes, units));
  }
  
  return {
    programId: template.programId,
    programName: template.programName,
    version: template.version,
    generatedAt: new Date().toISOString(),
    trainingMaxes,
    units,
    weeks,
  };
}

/**
 * Calculate training maxes from 1RMs
 */
export function calculateTrainingMaxes(oneRepMaxes, tmPercent = 0.85, units = 'lb') {
  return {
    squat: roundWeight(oneRepMaxes.squat * tmPercent, units),
    bench: roundWeight(oneRepMaxes.bench * tmPercent, units),
    deadlift: roundWeight(oneRepMaxes.deadlift * tmPercent, units),
    ohp: roundWeight(oneRepMaxes.ohp * tmPercent, units),
  };
}

/**
 * Load the plan template from public folder
 */
export async function loadPlanTemplate() {
  const response = await fetch('/plan.template.json');
  if (!response.ok) {
    throw new Error('Failed to load plan template');
  }
  return response.json();
}

