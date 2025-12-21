import type { Profile, Strength } from "./types.js";

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

/**
 * Validate profile data against v1 contract
 */
export function validateProfile(profile: any): ValidationResult {
  // A) Training Schedule
  if (typeof profile.trainingDaysPerWeek !== "number" || profile.trainingDaysPerWeek < 3 || profile.trainingDaysPerWeek > 6) {
    return { valid: false, error: "trainingDaysPerWeek must be between 3 and 6" };
  }
  
  const validDays = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
  if (!profile.preferredStartDay || !validDays.includes(profile.preferredStartDay)) {
    return { valid: false, error: "preferredStartDay is required and must be one of: mon, tue, wed, thu, fri, sat, sun" };
  }
  
  if (profile.preferredUnits !== "lb" && profile.preferredUnits !== "kg") {
    return { valid: false, error: "preferredUnits must be 'lb' or 'kg'" };
  }
  
  // B) Non-Lifting Days
  if (typeof profile.nonLiftingDaysEnabled !== "boolean") {
    return { valid: false, error: "nonLiftingDaysEnabled must be a boolean" };
  }
  
  const validModes = ["pilates", "conditioning", "gpp", "mobility", "rest"];
  if (!validModes.includes(profile.nonLiftingDayMode)) {
    return { valid: false, error: "nonLiftingDayMode must be one of: pilates, conditioning, gpp, mobility, rest" };
  }
  
  if (!profile.conditioningLevel || !["low", "moderate", "high"].includes(profile.conditioningLevel)) {
    return { valid: false, error: "conditioningLevel is required and must be one of: low, moderate, high" };
  }
  
  return { valid: true };
}

/**
 * Validate strength data
 */
export function validateStrength(strength: any): ValidationResult {
  if (!strength.oneRepMaxes) {
    return { valid: false, error: "oneRepMaxes is required" };
  }
  const requiredLifts = ["squat", "bench", "deadlift", "ohp"];
  for (const lift of requiredLifts) {
    if (typeof strength.oneRepMaxes[lift] !== "number" || strength.oneRepMaxes[lift] <= 0) {
      return { valid: false, error: `oneRepMaxes.${lift} must be a positive number` };
    }
  }
  if (!strength.tmPolicy) {
    return { valid: false, error: "tmPolicy is required" };
  }
  if (typeof strength.tmPolicy.percent !== "number" || strength.tmPolicy.percent < 0.80 || strength.tmPolicy.percent > 0.90) {
    return { valid: false, error: "tmPolicy.percent must be between 0.80 and 0.90" };
  }
  if (strength.tmPolicy.rounding !== "5lb" && strength.tmPolicy.rounding !== "2.5kg") {
    return { valid: false, error: "tmPolicy.rounding must be '5lb' or '2.5kg'" };
  }
  return { valid: true };
}

/**
 * Round to nearest increment
 */
export function roundToNearest(value: number, increment: number): number {
  return Math.round(value / increment) * increment;
}

/**
 * Calculate training max for a single lift
 */
export function calculateTrainingMax(oneRM: number, tmPercent: number, rounding: "5lb" | "2.5kg"): number {
  const tm = oneRM * tmPercent;
  const increment = rounding === "2.5kg" ? 2.5 : 5;
  return roundToNearest(Math.floor(tm), increment);
}

/**
 * Calculate all training maxes
 */
export function calculateTrainingMaxes(
  oneRepMaxes: Strength["oneRepMaxes"],
  tmPolicy: Strength["tmPolicy"]
): Strength["trainingMaxes"] {
  return {
    squat: calculateTrainingMax(oneRepMaxes.squat, tmPolicy.percent, tmPolicy.rounding),
    bench: calculateTrainingMax(oneRepMaxes.bench, tmPolicy.percent, tmPolicy.rounding),
    deadlift: calculateTrainingMax(oneRepMaxes.deadlift, tmPolicy.percent, tmPolicy.rounding),
    ohp: calculateTrainingMax(oneRepMaxes.ohp, tmPolicy.percent, tmPolicy.rounding),
  };
}


