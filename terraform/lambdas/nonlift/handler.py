import json
import sys
import os
import random

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.response import success_response, error_response
from shared.jwt_validator import validate_user_context, get_dynamodb_user_key
from shared.s3_config import get_app_config
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DATA_TABLE']
data_table = dynamodb.Table(table_name)

def get_user_settings(user_id: str):
    """Get user's program settings."""
    pk = get_dynamodb_user_key(user_id)
    response = data_table.get_item(
        Key={'userEmail': pk, 'dataType': 'PROGRAM_SETTINGS'}
    )
    return response.get('Item')

def generate_gpp_workout(settings: dict, exercises: list):
    """Generate GPP/Krypteia workout."""
    conditioning_level = settings.get('conditioningLevel', 'moderate')
    constraints = settings.get('constraints', [])
    equipment = settings.get('equipment', [])
    
    # Determine rounds based on conditioning level
    rounds = 5 if conditioning_level == 'high' else 4
    
    # Filter exercises by slot tags
    carries = [ex for ex in exercises if 'carry' in ex.get('slotTags', [])]
    single_leg = [ex for ex in exercises if 'single_leg' in ex.get('slotTags', []) or 'single_leg_hinge' in ex.get('slotTags', [])]
    core = [ex for ex in exercises if 'core_anti_rotation' in ex.get('slotTags', []) or 'core_anti_extension' in ex.get('slotTags', [])]
    
    # Filter by constraints and equipment
    def filter_exercises(ex_list):
        filtered = [
            ex for ex in ex_list
            if not any(c in ex.get('constraintsBlocked', []) for c in constraints)
        ]
        if equipment:
            filtered = [
                ex for ex in filtered
                if any(eq in equipment for eq in ex.get('equipment', []))
            ]
        return filtered
    
    carries = filter_exercises(carries)
    single_leg = filter_exercises(single_leg)
    core = filter_exercises(core)
    
    return {
        'type': 'gpp_krypteia',
        'label': 'GPP / Krypteia',
        'conditioning': {
            'modality': 'bike' if 'bike' in equipment else 'run',
            'prescription': '10 rounds: 20s hard / 40s easy' if conditioning_level == 'moderate' else '8 rounds: 30s hard / 30s easy',
            'targetRPE': 8 if conditioning_level == 'moderate' else 9
        },
        'circuit': {
            'rounds': rounds,
            'slots': [
                {
                    'slotId': 'carry',
                    'label': 'Carry',
                    'exercises': [{'id': ex['exerciseId'], 'name': ex['name']} for ex in carries[:10]],
                    'targetReps': '40-60m'
                },
                {
                    'slotId': 'single_leg',
                    'label': 'Single Leg Movement',
                    'exercises': [{'id': ex['exerciseId'], 'name': ex['name']} for ex in single_leg[:10]],
                    'targetReps': '8-12/side'
                },
                {
                    'slotId': 'core',
                    'label': 'Core Movement',
                    'exercises': [{'id': ex['exerciseId'], 'name': ex['name']} for ex in core[:10]],
                    'targetReps': '10-15'
                }
            ]
        },
        'notes': [
            'Select exercises for each slot',
            'Complete all rounds with minimal rest',
            'Total workout: 25-30 minutes'
        ]
    }

def generate_mobility_workout(week_index: int, exercises: list):
    """Generate mobility workout with rotating secondary focus."""
    hip_mobility = [ex for ex in exercises if 'mobility_hips_ir_er' in ex.get('slotTags', [])]
    hip_flexors = [ex for ex in exercises if 'mobility_hip_flexors' in ex.get('slotTags', [])]
    ankles = [ex for ex in exercises if 'mobility_ankles' in ex.get('slotTags', [])]
    t_spine = [ex for ex in exercises if 'mobility_t_spine' in ex.get('slotTags', [])]
    shoulders = [ex for ex in exercises if 'mobility_shoulders' in ex.get('slotTags', [])]
    
    # Rotate secondary focus by week
    secondary_options = [
        ('Ankle Mobility', ankles),
        ('T-Spine Mobility', t_spine),
        ('Shoulder Mobility', shoulders)
    ]
    secondary_label, secondary_exercises = secondary_options[week_index % len(secondary_options)]
    
    selected_hip = random.choice(hip_mobility + hip_flexors) if (hip_mobility or hip_flexors) else None
    selected_secondary = random.choice(secondary_exercises) if secondary_exercises else None
    
    exercises_list = [
        {
            'name': '90/90 Hip Assessment',
            'prescription': 'Hold as long as possible each side',
            'notes': 'Record your time - track progress'
        },
        {
            'name': selected_hip['name'] if selected_hip else '90/90 Hip Stretch',
            'prescription': '2 sets × 60s each side + 10 transitions',
            'notes': 'Focus on hip internal/external rotation'
        }
    ]
    
    if selected_secondary:
        exercises_list.append({
            'name': selected_secondary['name'],
            'prescription': '2 sets × 60s each side' if 'ankle' in secondary_label.lower() else '2 sets × 10-15 each side',
            'notes': selected_secondary.get('notes', '')
        })
    
    return {
        'type': 'mobility',
        'label': 'Mobility',
        'exercises': exercises_list,
        'notes': [
            'Move slowly and controlled',
            'Focus on end ranges of motion',
            'Record assessment times to track progress',
            'Total workout: 20-25 minutes'
        ]
    }

def generate_active_recovery_workout(settings: dict, exercises: list):
    """Generate active recovery workout."""
    equipment = settings.get('equipment', [])
    modality = 'bike' if 'bike' in equipment else 'walk'
    
    hip_mobility = [ex for ex in exercises if 'mobility_hips_ir_er' in ex.get('slotTags', [])]
    selected_hip = random.choice(hip_mobility) if hip_mobility else None
    
    return {
        'type': 'active_recovery',
        'label': 'Active Recovery',
        'exercises': [
            {
                'name': f'Zone 2 {modality.capitalize()}',
                'prescription': '20-25 minutes',
                'notes': 'Easy conversational pace. RPE 4-6'
            },
            {
                'name': selected_hip['name'] if selected_hip else 'Hip Mobility',
                'prescription': '5 minutes',
                'notes': 'Focus on hip internal/external rotation'
            },
            {
                'name': 'Static Stretching',
                'prescription': '5-10 minutes',
                'notes': 'Major muscle groups. Hold each stretch 30-60s'
            }
        ],
        'notes': [
            'Keep intensity very low',
            'Focus on recovery and blood flow',
            'No intervals, no heavy work'
        ]
    }

def generate_day(user_id: str, day_type: str, week_index: int, request_id: str) -> dict:
    """Generate a non-lifting day workout."""
    try:
        settings = get_user_settings(user_id)
        if not settings:
            return error_response(404, 'NOT_FOUND', 'Program settings not found', request_id)
        
        exercise_library = get_app_config('config/exercises.latest.json')
        exercises = exercise_library['exercises']
        
        if day_type == 'gpp_krypteia':
            workout = generate_gpp_workout(settings, exercises)
        elif day_type == 'mobility':
            workout = generate_mobility_workout(week_index, exercises)
        elif day_type == 'active_recovery':
            workout = generate_active_recovery_workout(settings, exercises)
        else:
            return error_response(400, 'INVALID_TYPE', f'Invalid day type: {day_type}', request_id)
        
        return success_response(200, workout)
    
    except Exception as e:
        print(f"Error generating non-lift day: {e}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def handler(event, context):
    """
    Handle non-lifting day generation (requires authentication).
    
    Routes:
    - GET /nonlift/day?type=gpp_krypteia|mobility|active_recovery&weekIndex=N
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
            day_type = query_params.get('type', 'gpp_krypteia')
            week_index = int(query_params.get('weekIndex', 1))
            return generate_day(user_id, day_type, week_index, request_id)
        
        return error_response(405, 'METHOD_NOT_ALLOWED', 'Method not allowed', request_id)
    
    except Exception as e:
        print(f"Handler error: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', context.aws_request_id)

