#!/bin/bash

# Define the base URL for the Flask API
BASE_URL="http://localhost:5001/api"

# Flag to control whether to echo JSON output
ECHO_JSON=false

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    --echo-json) ECHO_JSON=true ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

###############################################
#
# Health checks
#
###############################################

# Function to check the health of the service
check_health() {
  echo "Checking health status..."
  response=$(curl -s -X GET "$BASE_URL/health")
  if echo "$response" | grep -q '"status": "healthy"'; then
    echo "Service is healthy."
  else
    echo "Health check failed."
    exit 1
  fi
}

# Function to check the database connection
check_db() {
  echo "Checking database connection..."
  response=$(curl -s -X GET "$BASE_URL/db-check")
  if echo "$response" | grep -q '"database_status": "healthy"'; then
    echo "Database connection is healthy."
  else
    echo "Database check failed."
    exit 1
  fi
}

##########################################################
#
# Meal Management
#
##########################################################

create_meal() {
  meal=$1
  cuisine=$2
  price=$3
  difficulty=$4

  echo "Creating meal ($meal - $cuisine, Price: $price, Difficulty: $difficulty)..."
  response=$(curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty\"}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal '$meal' added successfully."
  else
    echo "Failed to add meal '$meal'."
    exit 1
  fi
}

get_meal_by_id() {
  meal_id=$1
  echo "Getting meal by ID ($meal_id)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-id/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by ID ($meal_id)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (ID $meal_id):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by ID ($meal_id)."
    exit 1
  fi
}

get_meal_by_name() {
  meal_name=$1
  echo "Getting meal by name ($meal_name)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-name/$meal_name")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by name ($meal_name)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (Name $meal_name):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by name ($meal_name)."
    exit 1
  fi
}

delete_meal_by_id() {
  meal_id=$1
  echo "Deleting meal by ID ($meal_id)..."
  response=$(curl -s -X DELETE "$BASE_URL/delete-meal/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal deleted successfully by ID ($meal_id)."
  else
    echo "Failed to delete meal by ID ($meal_id)."
    exit 1
  fi
}

############################################################
#
# Combat Management
#
############################################################

prep_combatant() {
  meal_id=$1
  echo "Preparing combatant with Meal ID ($meal_id)..."
  response=$(curl -s -X POST "$BASE_URL/battle/prep-combatant" -H "Content-Type: application/json" \
    -d "{\"meal_id\":$meal_id}")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatant prepared successfully for Meal ID ($meal_id)."
  else
    echo "Failed to prepare combatant for Meal ID ($meal_id)."
    exit 1
  fi
}

get_combatants() {
  echo "Retrieving current combatants..."
  response=$(curl -s -X GET "$BASE_URL/battle/get-combatants")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatants retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Combatants JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to retrieve combatants."
    exit 1
  fi
}

conduct_battle() {
  echo "Conducting battle between combatants..."
  response=$(curl -s -X POST "$BASE_URL/battle/battle")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Battle conducted successfully."
  else
    echo "Failed to conduct battle."
    exit 1
  fi
}

clear_combatants() {
  echo "Clearing all combatants..."
  response=$(curl -s -X POST "$BASE_URL/battle/clear-combatants")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatants cleared successfully."
  else
    echo "Failed to clear combatants."
    exit 1
  fi
}

############################################################
#
# Main Execution
#
############################################################

# Health checks
check_health
check_db

# Create some meals
create_meal "Spaghetti" "Italian" 12.50 "MED"
create_meal "Sushi" "Japanese" 15.00 "HIGH"
create_meal "Taco" "Mexican" 8.00 "LOW"

# Prepare combatants
prep_combatant 1
prep_combatant 2

# Retrieve combatants
get_combatants

# Conduct battle
conduct_battle

# Retrieve combatants again
get_combatants

# Clear all combatants
clear_combatants

echo "All tests passed successfully!"
