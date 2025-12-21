#!/bin/bash
set -e

# Seed script for Styrkr Exercise Library
# Populates DynamoDB with exhaustive exercise list for 5/3/1 Krypteia + longevity program

# Configuration
TABLE_NAME="${CONFIG_TABLE_NAME:-styrkr_app_config}"
AWS_REGION="${AWS_REGION:-us-east-1}"
LIBRARY_PK="LIBRARY#EXERCISES"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

# Verify AWS credentials
echo -e "${BLUE}🔍 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity --region "$AWS_REGION" &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured or invalid${NC}"
    echo "Run: aws configure"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials valid${NC}"

# Verify table exists
echo -e "${BLUE}🔍 Checking if table exists...${NC}"
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" &> /dev/null; then
    echo -e "${RED}❌ Table '$TABLE_NAME' does not exist in region '$AWS_REGION'${NC}"
    echo "Available tables:"
    aws dynamodb list-tables --region "$AWS_REGION" --query 'TableNames' --output text
    exit 1
fi
echo -e "${GREEN}✓ Table '$TABLE_NAME' exists${NC}"

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Function to create exercise JSON
create_exercise() {
    local exercise_id="$1"
    local name="$2"
    local category="$3"
    local movement_patterns="$4"
    local slot_tags="$5"
    local equipment="$6"
    local constraints_blocked="$7"
    local fatigue_score="$8"
    local notes="$9"
    
    cat <<EOF
{
    "PK": {"S": "$LIBRARY_PK"},
    "SK": {"S": "EXERCISE#$exercise_id"},
    "type": {"S": "exercise"},
    "exerciseId": {"S": "$exercise_id"},
    "name": {"S": "$name"},
    "category": {"S": "$category"},
    "movementPatterns": {"L": [$movement_patterns]},
    "slotTags": {"L": [$slot_tags]},
    "equipment": {"L": [$equipment]},
    "constraintsBlocked": {"L": [$constraints_blocked]},
    "fatigueScore": {"N": "$fatigue_score"},
    "notes": {"S": "$notes"},
    "createdAt": {"S": "$TIMESTAMP"},
    "updatedAt": {"S": "$TIMESTAMP"}
}
EOF
}

# Function to put item in DynamoDB
put_exercise() {
    local json="$1"
    local exercise_name="$2"
    
    echo -e "${BLUE}  → Adding: $exercise_name${NC}"
    
    if aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item "$json" \
        --region "$AWS_REGION" \
        --no-cli-pager 2>&1; then
        echo -e "${GREEN}    ✓ Success${NC}"
        return 0
    else
        echo -e "${RED}    ✗ Failed${NC}"
        echo -e "${YELLOW}    JSON: $json${NC}"
        return 1
    fi
}

# Helper to format string array
s() {
    echo "{\"S\": \"$1\"}"
}

# Helper to format array of strings
arr() {
    local result=""
    for item in "$@"; do
        if [ -n "$result" ]; then
            result="$result,"
        fi
        result="$result{\"S\": \"$item\"}"
    done
    echo "$result"
}

echo "================================================================================"
echo "Seeding Exercise Library"
echo "Table: $TABLE_NAME"
echo "Region: $AWS_REGION"
echo "================================================================================"

EXERCISE_COUNT=0

# Main Lifts - Squat
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Main Lifts - Squat${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "back-squat" "Back Squat" "main" "$(arr squat)" "$(arr main_lift squat_variation)" "$(arr barbell)" "$(arr no_deep_squat)" "5" "Primary squat movement")" "Back Squat"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "ssb-squat" "Safety Squat Bar Squat" "main" "$(arr squat)" "$(arr main_lift squat_variation)" "$(arr ssb)" "$(arr no_deep_squat shoulder_issue)" "5" "Easier on shoulders, more quad emphasis")" "Safety Squat Bar Squat"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "pause-squat" "Pause Squat" "main" "$(arr squat)" "$(arr squat_variation)" "$(arr barbell)" "$(arr no_deep_squat)" "5" "2-3 second pause in the hole")" "Pause Squat"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "tempo-squat" "Tempo Squat" "main" "$(arr squat)" "$(arr squat_variation)" "$(arr barbell)" "$(arr no_deep_squat)" "4" "Controlled eccentric (3-5 seconds down)")" "Tempo Squat"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "box-squat" "Box Squat" "main" "$(arr squat)" "$(arr squat_variation)" "$(arr barbell)" "" "4" "Sit back to box, pause, explode up")" "Box Squat"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "front-squat" "Front Squat" "supplemental" "$(arr squat)" "$(arr squat_variation)" "$(arr barbell)" "$(arr no_deep_squat shoulder_issue)" "4" "More upright, quad-dominant")" "Front Squat"
((EXERCISE_COUNT++))

# Main Lifts - Bench
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Main Lifts - Bench${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "flat-bench" "Flat Bench Press" "main" "$(arr horizontal_push)" "$(arr main_lift bench_variation)" "$(arr barbell)" "$(arr shoulder_issue)" "5" "Primary bench movement")" "Flat Bench Press"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "close-grip-bench" "Close Grip Bench Press" "main" "$(arr horizontal_push)" "$(arr bench_variation triceps)" "$(arr barbell)" "$(arr shoulder_issue elbow_issue)" "4" "Hands inside shoulder width, more triceps")" "Close Grip Bench Press"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "spoto-press" "Spoto Press" "main" "$(arr horizontal_push)" "$(arr bench_variation)" "$(arr barbell)" "$(arr shoulder_issue)" "4" "Pause 1-2 inches above chest")" "Spoto Press"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "tempo-bench" "Tempo Bench Press" "main" "$(arr horizontal_push)" "$(arr bench_variation)" "$(arr barbell)" "$(arr shoulder_issue)" "4" "Controlled eccentric (3-5 seconds down)")" "Tempo Bench Press"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "larsen-press" "Larsen Press" "main" "$(arr horizontal_push)" "$(arr bench_variation)" "$(arr barbell)" "$(arr shoulder_issue)" "4" "Feet up, no leg drive")" "Larsen Press"
((EXERCISE_COUNT++))

# Main Lifts - Deadlift
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Main Lifts - Deadlift${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "conventional-deadlift" "Conventional Deadlift" "main" "$(arr hinge)" "$(arr main_lift hinge_variation posterior_chain)" "$(arr barbell)" "$(arr low_back_issue)" "5" "Primary deadlift movement")" "Conventional Deadlift"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "sumo-deadlift" "Sumo Deadlift" "main" "$(arr hinge)" "$(arr main_lift hinge_variation)" "$(arr barbell)" "$(arr low_back_issue)" "5" "Wide stance, more upright torso")" "Sumo Deadlift"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "rdl-barbell" "Romanian Deadlift (Barbell)" "supplemental" "$(arr hinge)" "$(arr hinge_variation posterior_chain)" "$(arr barbell)" "$(arr low_back_issue)" "4" "Hamstring emphasis, slight knee bend")" "Romanian Deadlift (Barbell)"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "rdl-ssb" "Romanian Deadlift (SSB)" "supplemental" "$(arr hinge)" "$(arr hinge_variation posterior_chain)" "$(arr ssb)" "$(arr low_back_issue shoulder_issue)" "4" "Easier on shoulders")" "Romanian Deadlift (SSB)"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "pause-deadlift" "Pause Deadlift" "main" "$(arr hinge)" "$(arr hinge_variation)" "$(arr barbell)" "$(arr low_back_issue)" "5" "Pause just below or above knee")" "Pause Deadlift"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "deficit-deadlift" "Deficit Deadlift" "main" "$(arr hinge)" "$(arr hinge_variation)" "$(arr barbell)" "$(arr low_back_issue)" "5" "Stand on 1-3 inch platform")" "Deficit Deadlift"
((EXERCISE_COUNT++))

# Main Lifts - OHP
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Main Lifts - Overhead Press${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "strict-press" "Strict Overhead Press" "main" "$(arr vertical_push)" "$(arr main_lift press_variation)" "$(arr barbell)" "$(arr no_overhead shoulder_issue)" "4" "Primary overhead press")" "Strict Overhead Press"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "seated-db-press" "Seated Dumbbell Press" "supplemental" "$(arr vertical_push)" "$(arr press_variation upper_push_vertical)" "$(arr db)" "$(arr no_overhead shoulder_issue)" "3" "Seated with back support")" "Seated Dumbbell Press"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "push-press" "Push Press" "supplemental" "$(arr vertical_push)" "$(arr press_variation)" "$(arr barbell)" "$(arr no_overhead shoulder_issue)" "4" "Use leg drive to assist")" "Push Press"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "landmine-press" "Landmine Press" "supplemental" "$(arr vertical_push)" "$(arr press_variation upper_push_vertical)" "$(arr landmine barbell)" "" "3" "Shoulder-friendly pressing angle")" "Landmine Press"
((EXERCISE_COUNT++))

# Accessories - Pull
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Accessories - Pull${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "pullups" "Pull-ups" "accessory" "$(arr vertical_pull)" "$(arr upper_pull_vertical)" "$(arr pullup_bar)" "$(arr shoulder_issue elbow_issue)" "3" "Bodyweight or weighted")" "Pull-ups"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "weighted-pullups" "Weighted Pull-ups" "accessory" "$(arr vertical_pull)" "$(arr upper_pull_vertical)" "$(arr pullup_bar)" "$(arr shoulder_issue elbow_issue)" "4" "Add weight via belt or vest")" "Weighted Pull-ups"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "ring-rows" "Ring Rows" "accessory" "$(arr horizontal_pull)" "$(arr upper_pull_horizontal scap_stability)" "$(arr rings)" "" "2" "Adjust angle for difficulty")" "Ring Rows"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "db-rows" "Dumbbell Rows" "accessory" "$(arr horizontal_pull)" "$(arr upper_pull_horizontal)" "$(arr db)" "" "3" "Single arm or bent over")" "Dumbbell Rows"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "chest-supported-rows" "Chest Supported Rows" "accessory" "$(arr horizontal_pull)" "$(arr upper_pull_horizontal)" "$(arr db)" "" "2" "Removes lower back stress")" "Chest Supported Rows"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "inverted-rows" "Inverted Rows" "accessory" "$(arr horizontal_pull)" "$(arr upper_pull_horizontal scap_stability)" "$(arr barbell)" "" "2" "Barbell in rack at waist height")" "Inverted Rows"
((EXERCISE_COUNT++))

# Accessories - Push
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Accessories - Push${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "ring-dips" "Ring Dips" "accessory" "$(arr vertical_push)" "$(arr upper_push_vertical triceps)" "$(arr rings)" "$(arr shoulder_issue elbow_issue)" "3" "Bodyweight or weighted")" "Ring Dips"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "weighted-ring-dips" "Weighted Ring Dips" "accessory" "$(arr vertical_push)" "$(arr upper_push_vertical triceps)" "$(arr rings)" "$(arr shoulder_issue elbow_issue)" "4" "Add weight via belt")" "Weighted Ring Dips"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "ring-pushups" "Ring Push-ups" "accessory" "$(arr horizontal_push)" "$(arr upper_push_horizontal scap_stability)" "$(arr rings)" "$(arr shoulder_issue)" "2" "Unstable surface increases difficulty")" "Ring Push-ups"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "pushups" "Push-ups" "accessory" "$(arr horizontal_push)" "$(arr upper_push_horizontal)" "$(arr bodyweight)" "$(arr shoulder_issue)" "2" "Standard or elevated feet")" "Push-ups"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "db-incline-press" "Dumbbell Incline Press" "accessory" "$(arr horizontal_push)" "$(arr upper_push_horizontal)" "$(arr db)" "$(arr shoulder_issue)" "3" "30-45 degree incline")" "Dumbbell Incline Press"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "db-floor-press" "Dumbbell Floor Press" "accessory" "$(arr horizontal_push)" "$(arr upper_push_horizontal triceps)" "$(arr db)" "" "3" "Shoulder-friendly, limited ROM")" "Dumbbell Floor Press"
((EXERCISE_COUNT++))

# Single Leg
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Accessories - Single Leg${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "db-step-ups" "Dumbbell Step-ups" "accessory" "$(arr single_leg)" "$(arr single_leg_knee_dominant)" "$(arr db)" "$(arr no_knee_flexion)" "3" "Box height at or below knee")" "Dumbbell Step-ups"
((EXERCISE_COUNT++))

# Conditioning
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Conditioning${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "assault-bike-intervals" "Assault Bike Intervals" "conditioning" "" "$(arr intervals_short)" "$(arr bike)" "" "4" "Short high-intensity intervals (10-30s)")" "Assault Bike Intervals"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "rower-intervals" "Rower Intervals" "conditioning" "$(arr hinge)" "$(arr intervals_short)" "$(arr rower)" "$(arr low_back_issue)" "4" "Short high-intensity intervals (30-90s)")" "Rower Intervals"
((EXERCISE_COUNT++))

# Mobility
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Mobility${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
put_exercise "$(create_exercise "90-90-transitions" "90/90 Transitions" "mobility" "$(arr rotation)" "$(arr hip_ir_er)" "$(arr bodyweight)" "" "1" "Hip internal/external rotation")" "90/90 Transitions"
((EXERCISE_COUNT++))

put_exercise "$(create_exercise "hip-cars" "Hip CARs" "mobility" "$(arr rotation)" "$(arr hip_ir_er)" "$(arr bodyweight)" "" "1" "Controlled articular rotations")" "Hip CARs"
((EXERCISE_COUNT++))

echo ""
echo "================================================================================"
echo -e "${GREEN}✓ Successfully seeded $EXERCISE_COUNT exercises!${NC}"
echo "================================================================================"

# Verify exercises were added
echo ""
echo -e "${BLUE}🔍 Verifying exercises in DynamoDB...${NC}"
ITEM_COUNT=$(aws dynamodb query \
    --table-name "$TABLE_NAME" \
    --key-condition-expression "PK = :pk" \
    --expression-attribute-values '{":pk":{"S":"LIBRARY#EXERCISES"}}' \
    --select COUNT \
    --region "$AWS_REGION" \
    --output json | jq -r '.Count')

echo -e "${GREEN}✓ Found $ITEM_COUNT exercises in table${NC}"

if [ "$ITEM_COUNT" -ne "$EXERCISE_COUNT" ]; then
    echo -e "${YELLOW}⚠️  Warning: Expected $EXERCISE_COUNT but found $ITEM_COUNT${NC}"
fi

echo ""
echo "================================================================================"
echo "Next steps:"
echo "1. ✓ Exercises seeded to DynamoDB"
echo "2. Call POST /admin/library/publish to generate the JSON snapshot"
echo "3. Access the library via CloudFront at /config/exercises.latest.json"
echo "================================================================================"
echo ""

