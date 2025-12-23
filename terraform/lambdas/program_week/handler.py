import json
import sys
import os
from datetime import datetime, timedelta
import boto3
import random

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.response import success_response, error_response
from shared.jwt_validator import validate_user_context, get_dynamodb_user_key
from shared.s3_config import get_app_config

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DATA_TABLE']
data_table = dynamodb.Table(table_name)

def get_user_strength_data(user_id: str):
    """Get user's 1RMs from DynamoDB."""
    pk = get_dynamodb_user_key(user_id)
    response = data_table.get_item(
        Key={'userEmail': pk, 'dataType': 'STRENGTH'}
    )
    return response.get('Item')

def get_user_settings(user_id: str):
    """Get user's program settings from DynamoDB."""
    pk = get_dynamodb_user_key(user_id)
    response = data_table.get_item(
        Key={'userEmail': pk, 'dataType': 'PROGRAM_SETTINGS'}
    )
    return response.get('Item')

def calculate_training_max(one_rm: float, tm_percent: int) -> float:
    """Calculate training max from 1RM."""
    return one_rm * (tm_percent / 100.0)

def round_weight(weight: float, rounding: int) -> float:
    """Round weight to nearest rounding increment."""
    return round(weight / rounding) * rounding

def compute_work_sets(set_scheme: dict, training_max: float, rounding: int):
    """Compute work sets from set scheme and training max."""
    sets = []
    for work_set in set_scheme['workSets']:
        weight = training_max * work_set['pctTM']
        rounded_weight = round_weight(weight, rounding)
        sets.append({
            'weight': rounded_weight,
            'targetReps': work_set['reps'],
            'pctTM': work_set['pctTM']
        })
    return sets

def get_phase_for_week(week_index: int, template: dict):
    """Determine which phase a week belongs to."""
    for phase in template['macrocycle']['phases']:
        if week_index in phase['weeks']:
            return phase
    return None

def select_exercises_for_slots(slots: list, exercises: list, constraints: list, equipment: list, used_exercises: set):
    """
    Select exercises for assistance slots.
    
    Args:
        slots: List of assistance slot definitions
        exercises: Exercise library
        constraints: User constraints (e.g., 'knee_issue')
        equipment: Available equipment
        used_exercises: Set of already-used exercise IDs (for oneExercisePerSlot)
    
    Returns:
        Dict mapping slotId to selected exercise
    """
    selected = {}
    
    for slot in slots:
        slot_id = slot['slotId']
        
        # Filter exercises by slot tag
        candidates = [
            ex for ex in exercises
            if slot_id in ex.get('slotTags', [])
        ]
        
        # Filter by constraints
        candidates = [
            ex for ex in candidates
            if not any(c in ex.get('constraintsBlocked', []) for c in constraints)
        ]
        
        # Filter by equipment
        candidates = [
            ex for ex in candidates
            if any(eq in equipment for eq in ex.get('equipment', []))
        ]
        
        # Filter out already-used exercises (oneExercisePerSlot rule)
        candidates = [
            ex for ex in candidates
            if ex['exerciseId'] not in used_exercises
        ]
        
        if candidates:
            exercise = random.choice(candidates)
            selected[slot_id] = {
                'exerciseId': exercise['exerciseId'],
                'name': exercise['name'],
                'minReps': slot.get('minReps', 10),
                'maxReps': slot.get('maxReps', 20)
            }
            used_exercises.add(exercise['exerciseId'])
        else:
            # Fallback if no candidates
            selected[slot_id] = {
                'exerciseId': f"placeholder_{slot_id}",
                'name': f"Any {slot_id.replace('_', ' ').title()}",
                'minReps': slot.get('minReps', 10),
                'maxReps': slot.get('maxReps', 20)
            }
    
    return selected

def render_week(user_id: str, week_index: int, request_id: str) -> dict:
    """Render a specific week's sessions."""
    try:
        # Get user data
        strength_data = get_user_strength_data(user_id)
        if not strength_data:
            return error_response(404, 'NOT_FOUND', 'Strength data not found. Please enter your 1RMs.', request_id)
        
        settings = get_user_settings(user_id)
        if not settings:
            return error_response(404, 'NOT_FOUND', 'Program settings not found', request_id)
        
        # Get config from S3
        template = get_app_config('config/plan.template.json')
        exercise_library = get_app_config('config/exercises.latest.json')
        
        # Get phase for this week
        phase = get_phase_for_week(week_index, template)
        if not phase:
            return error_response(400, 'INVALID_WEEK', f'Week {week_index} not found in program', request_id)
        
        # Calculate training maxes
        tm_percent = settings.get('tmPercent', 85)
        rounding = settings.get('rounding', 5)
        
        training_maxes = {
            'squat': calculate_training_max(float(strength_data.get('squat', 0)), tm_percent),
            'bench': calculate_training_max(float(strength_data.get('bench', 0)), tm_percent),
            'deadlift': calculate_training_max(float(strength_data.get('deadlift', 0)), tm_percent),
            'ohp': calculate_training_max(float(strength_data.get('ohp', 0)), tm_percent)
        }
        
        # Determine set scheme for this week
        if phase.get('mainLiftSchemeByWeekInCycle'):
            week_in_cycle = str(week_index)
            scheme_name = phase['mainLiftSchemeByWeekInCycle'].get(week_in_cycle, phase['mainLiftScheme'])
        else:
            scheme_name = phase['mainLiftScheme']
        
        set_scheme = template['setSchemes'][scheme_name]
        
        # Get session order (squat, bench, deadlift, ohp)
        session_order = ['SQUAT', 'BENCH', 'DEADLIFT', 'OHP']
        
        sessions = []
        used_exercises = set()
        
        for session_id in session_order:
            session_template = template['sessionTemplates'][session_id]
            lift_id = session_template['mainLiftId']
            
            # Compute main lift sets
            main_sets = compute_work_sets(set_scheme, training_maxes[lift_id], rounding)
            
            # Compute supplemental (FSL)
            supplemental = None
            if phase['rules'].get('supplementalEnabled', True):
                fsl_weight = main_sets[0]['weight']  # First set is FSL weight
                supplemental = {
                    'type': 'fsl_main_lift',
                    'label': 'FSL (Main Lift)',
                    'sets': 5,
                    'repsRange': [3, 10],
                    'weight': fsl_weight
                }
            
            # Select assistance exercises
            constraints = settings.get('constraints', [])
            equipment = settings.get('equipment', ['barbell', 'dumbbell', 'kb', 'band'])
            
            assistance = select_exercises_for_slots(
                session_template['assistanceSlots'],
                exercise_library['exercises'],
                constraints,
                equipment,
                used_exercises
            )
            
            # Circuit configuration
            circuit_rounds = phase['rules'].get('circuitRounds', 5)
            
            session = {
                'sessionId': session_id,
                'label': session_template['label'],
                'mainLiftId': lift_id,
                'setScheme': set_scheme['label'],
                'mainSets': main_sets,
                'supplemental': supplemental,
                'assistanceSlots': [
                    {
                        'slotId': slot_id,
                        **assistance[slot_id]
                    }
                    for slot_id in assistance
                ],
                'circuit': {
                    'enabled': True,
                    'rounds': circuit_rounds,
                    'style': 'EMOMish'
                }
            }
            
            sessions.append(session)
        
        result = {
            'weekIndex': week_index,
            'phase': phase['phaseId'],
            'phaseLabel': phase['label'],
            'sessions': sessions,
            'trainingMaxes': training_maxes
        }
        
        return success_response(200, result)
    
    except Exception as e:
        print(f"Error rendering week: {e}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def handler(event, context):
    """
    Handle program week rendering (requires authentication).
    
    Routes:
    - GET /program/week?weekIndex=N
    """
    try:
        request_id = context.aws_request_id
        method = event['requestContext']['http']['method']
        
        # Validate JWT and extract user context
        try:
            user_context = validate_user_context(event)
            user_id = user_context['userId']
        except ValueError as e:
            return error_response(403, 'FORBIDDEN', str(e), request_id)
        
        if method == 'GET':
            query_params = event.get('queryStringParameters', {})
            week_index = int(query_params.get('weekIndex', 1))
            return render_week(user_id, week_index, request_id)
        
        return error_response(405, 'METHOD_NOT_ALLOWED', 'Method not allowed', request_id)
    
    except Exception as e:
        print(f"Handler error: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', context.aws_request_id)

