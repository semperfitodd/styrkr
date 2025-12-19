from typing import Dict, Tuple

def validate_profile(profile: dict) -> Tuple[bool, str | None]:
    if not isinstance(profile.get('trainingDaysPerWeek'), int) or not (3 <= profile['trainingDaysPerWeek'] <= 6):
        return False, "trainingDaysPerWeek must be between 3 and 6"
    
    if profile.get('preferredUnits') not in ['lb', 'kg']:
        return False, "preferredUnits must be 'lb' or 'kg'"
    
    if not isinstance(profile.get('includeNonLiftingDays'), bool):
        return False, "includeNonLiftingDays must be a boolean"
    
    valid_modes = ['pilates', 'conditioning', 'gpp', 'mobility', 'rest']
    if profile.get('nonLiftingDayMode') not in valid_modes:
        return False, f"nonLiftingDayMode must be one of: {', '.join(valid_modes)}"
    
    if not isinstance(profile.get('constraints'), list):
        return False, "constraints must be an array"
    
    if profile.get('conditioningLevel') and profile['conditioningLevel'] not in ['low', 'moderate', 'high']:
        return False, "conditioningLevel must be one of: low, moderate, high"
    
    if profile.get('preferredStartDay'):
        valid_days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        if profile['preferredStartDay'] not in valid_days:
            return False, "preferredStartDay must be a valid day abbreviation"
    
    if profile.get('movementCapabilities'):
        mc = profile['movementCapabilities']
        if not isinstance(mc.get('pullups'), bool) or not isinstance(mc.get('ringDips'), bool):
            return False, "movementCapabilities.pullups and ringDips must be booleans"
        if mc.get('muscleUps') not in ['none', 'bar', 'rings']:
            return False, "movementCapabilities.muscleUps must be: none, bar, or rings"
    
    return True, None

def validate_strength(strength: dict) -> Tuple[bool, str | None]:
    if 'oneRepMaxes' not in strength:
        return False, "oneRepMaxes is required"
    
    required_lifts = ['squat', 'bench', 'deadlift', 'ohp']
    for lift in required_lifts:
        value = strength['oneRepMaxes'].get(lift)
        if not isinstance(value, (int, float)) or value <= 0:
            return False, f"oneRepMaxes.{lift} must be a positive number"
    
    if 'tmPolicy' not in strength:
        return False, "tmPolicy is required"
    
    percent = strength['tmPolicy'].get('percent')
    if not isinstance(percent, (int, float)) or not (0.80 <= percent <= 0.90):
        return False, "tmPolicy.percent must be between 0.80 and 0.90"
    
    if strength['tmPolicy'].get('rounding') not in ['5lb', '2.5kg']:
        return False, "tmPolicy.rounding must be '5lb' or '2.5kg'"
    
    return True, None

def round_to_nearest(value: float, increment: float) -> float:
    return round(value / increment) * increment

def calculate_training_max(one_rm: float, tm_percent: float, rounding: str) -> float:
    tm = one_rm * tm_percent
    increment = 2.5 if rounding == '2.5kg' else 5
    return round_to_nearest(int(tm), increment)

def calculate_training_maxes(one_rep_maxes: Dict[str, float], tm_policy: dict) -> Dict[str, float]:
    return {
        lift: calculate_training_max(
            one_rep_maxes[lift],
            tm_policy['percent'],
            tm_policy['rounding']
        )
        for lift in ['squat', 'bench', 'deadlift', 'ohp']
    }

