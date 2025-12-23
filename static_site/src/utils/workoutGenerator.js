import { loadExerciseLibrary } from './exerciseSelector';

let exerciseLibrary = null;

async function getExerciseLibrary() {
  if (!exerciseLibrary) {
    exerciseLibrary = await loadExerciseLibrary();
  }
  return exerciseLibrary;
}

function getExercisesBySlotTag(library, slotTag) {
  return library.exercises.filter(ex => ex.slotTags && ex.slotTags.includes(slotTag));
}

function getRandomItem(array) {
  return array[Math.floor(Math.random() * array.length)];
}

function shouldDowngradeIntensity(weekPhase) {
  return ['DELOAD', 'TEST'].includes(weekPhase);
}

function selectConditioning(constraints, equipment) {
  const available = [];
  
  if (!constraints.includes('no_running')) {
    available.push('run');
  }
  
  if (equipment.includes('bike')) {
    available.push('bike');
  }
  
  if (equipment.includes('rower')) {
    available.push('rower');
  }
  
  if (equipment.includes('jumprope') && !constraints.includes('knee_issue')) {
    available.push('jump_rope');
  }
  
  return available.length > 0 ? getRandomItem(available) : 'bike';
}

function getConditioiningPrescription(conditioningLevel, weekPhase) {
  if (shouldDowngradeIntensity(weekPhase)) {
    return {
      type: 'zone2',
      durationMin: 25,
      targetRPE: 5,
      description: 'Zone 2 steady pace',
    };
  }
  
  switch (conditioningLevel) {
    case 'low':
      return {
        type: 'zone2',
        durationMin: 30,
        targetRPE: 5,
        description: 'Zone 2 steady pace',
      };
    case 'moderate':
      return {
        type: 'intervals',
        work: '0:20',
        rest: '0:40',
        rounds: 10,
        targetRPE: 8,
        description: '10 rounds: 20s hard / 40s easy',
      };
    case 'high':
      return {
        type: 'intervals',
        work: '0:30',
        rest: '0:30',
        rounds: 8,
        targetRPE: 9,
        description: '8 rounds: 30s hard / 30s easy',
      };
    default:
      return {
        type: 'zone2',
        durationMin: 25,
        targetRPE: 5,
        description: 'Zone 2 steady pace',
      };
  }
}


export async function generateGPPWorkout(options = {}) {
  const {
    conditioningLevel = 'moderate',
    constraints = [],
    equipment = ['bike', 'rower', 'jumprope', 'kb', 'db', 'medball'],
    weekPhase = 'LEADER',
    durationTarget = 30,
  } = options;
  
  const library = await getExerciseLibrary();
  const modality = selectConditioning(constraints, equipment);
  const prescription = getConditioiningPrescription(conditioningLevel, weekPhase);
  
  const carries = getExercisesBySlotTag(library, 'carry');
  const coreExercises = [
    ...getExercisesBySlotTag(library, 'core_anti_rotation'),
    ...getExercisesBySlotTag(library, 'core_anti_extension'),
  ];
  const singleLegExercises = [
    ...getExercisesBySlotTag(library, 'single_leg'),
    ...getExercisesBySlotTag(library, 'single_leg_hinge'),
  ];
  
  const rounds = shouldDowngradeIntensity(weekPhase) ? 3 : (conditioningLevel === 'high' ? 5 : 4);
  
  return {
    sessionId: 'GPP',
    label: 'GPP / Krypteia',
    type: 'gpp',
    durationMin: durationTarget,
    isInteractive: true,
    conditioning: {
      modality,
      ...prescription,
    },
    circuit: {
      rounds,
      slots: [
        {
          slotId: 'carry',
          label: 'Carry',
          exercises: carries.map(ex => ({ id: ex.id, name: ex.name, notes: ex.notes })),
          targetReps: '40-60m',
        },
        {
          slotId: 'single_leg',
          label: 'Single Leg Movement',
          exercises: singleLegExercises.map(ex => ({ id: ex.id, name: ex.name, notes: ex.notes })),
          targetReps: '8-12/side',
        },
        {
          slotId: 'core',
          label: 'Core Movement',
          exercises: coreExercises.map(ex => ({ id: ex.id, name: ex.name, notes: ex.notes })),
          targetReps: '10-15',
        },
      ],
    },
    notes: [
      'Krypteia-style GPP work',
      'Select exercises for each slot',
      'Complete all rounds with minimal rest',
      `Total workout: ${durationTarget} minutes`,
    ],
  };
}

export async function generateMobilityWorkout(options = {}) {
  const {
    constraints = [],
    durationTarget = 25,
  } = options;
  
  const library = await getExerciseLibrary();
  
  const hipIRER = getExercisesBySlotTag(library, 'mobility_hips_ir_er');
  const hipFlexors = getExercisesBySlotTag(library, 'mobility_hip_flexors');
  const ankles = getExercisesBySlotTag(library, 'mobility_ankles');
  const tSpine = getExercisesBySlotTag(library, 'mobility_t_spine');
  const shoulders = getExercisesBySlotTag(library, 'mobility_shoulders');
  
  const selectedHip = getRandomItem([...hipIRER, ...hipFlexors]);
  const selectedAnkle = getRandomItem(ankles);
  const selectedTSpine = getRandomItem(tSpine);
  const selectedShoulder = getRandomItem(shoulders);
  
  const exercises = [];
  
  exercises.push({
    name: '90/90 Hip Assessment',
    reps: 'Hold as long as possible each side',
    notes: 'Record your time - track progress',
  });
  
  exercises.push({
    name: selectedHip?.name || '90/90 Hip Stretch',
    sets: 2,
    reps: '60s each side + 10 transitions',
    notes: selectedHip?.notes?.[0] || 'Focus on hip internal/external rotation',
  });
  
  const secondaryOptions = [];
  if (!constraints.includes('knee_issue')) {
    secondaryOptions.push({
      name: selectedAnkle?.name || 'Ankle Rocks',
      sets: 2,
      reps: '60s each side + 10 reps',
      notes: selectedAnkle?.notes?.[0] || 'Push knee forward over toes',
    });
  }
  
  secondaryOptions.push({
    name: selectedTSpine?.name || 'Thoracic Rotations',
    sets: 2,
    reps: '10-15 each side',
    notes: selectedTSpine?.notes?.[0] || 'Rotate from mid-back, not lower back',
  });
  
  if (!constraints.includes('shoulder_issue')) {
    secondaryOptions.push({
      name: selectedShoulder?.name || 'Wall Slides',
      sets: 2,
      reps: '10-15',
      notes: selectedShoulder?.notes?.[0] || 'Keep back flat against wall',
    });
  }
  
  exercises.push(getRandomItem(secondaryOptions));
  
  return {
    sessionId: 'MOBILITY',
    label: 'Mobility',
    type: 'mobility',
    durationMin: durationTarget,
    exercises,
    notes: [
      'Move slowly and controlled',
      'Focus on end ranges of motion',
      'Record assessment times to track progress',
      `Total workout: ${durationTarget} minutes`,
    ],
  };
}

export async function generateActiveRecoveryWorkout(options = {}) {
  const {
    constraints = [],
    equipment = ['bike', 'rower'],
    weekPhase = 'LEADER',
    durationTarget = 30,
  } = options;
  
  const library = await getExerciseLibrary();
  const modality = selectConditioning(constraints, equipment);
  
  const zone2Duration = shouldDowngradeIntensity(weekPhase) ? 20 : 25;
  
  const hipMobility = getExercisesBySlotTag(library, 'mobility_hips_ir_er');
  const tSpine = getExercisesBySlotTag(library, 'mobility_t_spine');
  
  const selectedHip = getRandomItem(hipMobility);
  const selectedTSpine = getRandomItem(tSpine);
  
  return {
    sessionId: 'REST',
    label: 'Active Recovery',
    type: 'rest',
    durationMin: durationTarget,
    exercises: [
      {
        name: `Zone 2 ${modality.charAt(0).toUpperCase() + modality.slice(1)}`,
        duration: `${zone2Duration} min`,
        notes: 'Easy conversational pace. RPE 4-6. Keep heart rate low',
      },
      {
        name: selectedHip?.name || 'Hip Mobility',
        duration: '5 min',
        notes: selectedHip?.notes?.[0] || 'Focus on hip internal/external rotation',
      },
      {
        name: selectedTSpine?.name || 'T-Spine Mobility',
        duration: '3 min',
        notes: selectedTSpine?.notes?.[0] || 'Gentle rotations',
      },
      {
        name: 'Static Stretching',
        duration: '5-10 min',
        notes: 'Major muscle groups. Hold each stretch 30-60s',
      },
    ],
    notes: [
      'Keep intensity very low',
      'Focus on recovery and blood flow',
      'No intervals, no heavy work',
      'Optional: sauna, ice bath, or massage',
    ],
  };
}

export function generatePilatesWorkout() {
  return {
    sessionId: 'PILATES',
    label: 'Pilates',
    type: 'pilates',
    exercises: [
      {
        name: 'Pilates Session',
        notes: 'Complete your Pilates routine',
      },
    ],
    notes: [
      'Complete your Pilates routine',
      'Focus on breath and core engagement',
      'Quality over quantity',
    ],
  };
}

