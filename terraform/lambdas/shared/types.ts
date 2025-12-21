// Shared TypeScript types for Styrkr

/**
 * User Profile v1 Contract
 * 
 * This is the authoritative definition of the user profile.
 * Profile is scoped per user (PK=USER#{sub}, SK=PROFILE).
 * 
 * Security: userId is NEVER accepted from client - always derived from JWT.
 * 
 * Explicitly NOT in profile:
 * - Exercise selections (managed by Exercise Library)
 * - Favorite exercises
 * - Per-slot exercise choices
 */
export interface Profile {
  // A) Training Schedule
  trainingDaysPerWeek: number; // 3-6
  preferredStartDay: "mon" | "tue" | "wed" | "thu" | "fri" | "sat" | "sun";
  preferredUnits: "lb" | "kg";
  
  // B) Non-Lifting Days
  nonLiftingDaysEnabled: boolean;
  nonLiftingDayMode: "pilates" | "conditioning" | "gpp" | "mobility" | "rest";
  conditioningLevel: "low" | "moderate" | "high";
  
  // Metadata (managed by backend)
  createdAt?: string;
  updatedAt?: string;
}

export interface Strength {
  oneRepMaxes: {
    squat: number;
    bench: number;
    deadlift: number;
    ohp: number;
  };
  tmPolicy: {
    percent: number;
    rounding: "5lb" | "2.5kg";
  };
  trainingMaxes?: {
    squat: number;
    bench: number;
    deadlift: number;
    ohp: number;
  };
  createdAt?: string;
  updatedAt?: string;
}

export interface ErrorResponse {
  error: {
    code: string;
    message: string;
    requestId: string;
  };
}


