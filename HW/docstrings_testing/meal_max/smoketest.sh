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
  curl -s -X GET "$BASE_URL/health" | grep -q '"status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Service is healthy."
  else
    echo "Health check failed."
    exit 1
  fi
}

# Function to check the database connection
check_db() {
  echo "Checking database connection..."
  curl -s -X GET "$BASE_URL/db-check" | grep -q '"database_status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Database connection is healthy."
  else
    echo "Database check failed."
    exit 1
  fi
}




##########################################################
#
# meals
#
##########################################################

clear_catalog() {
  echo "Clearing the catalog..."
  curl -s -X DELETE "$BASE_URL/clear-meals" | grep -q '"status": "success"'
}

create_meal() {
  id=$1
  meal=$2
  cuisine=$3
  price=$4
  difficulty=$5

  echo "Creating meal ($meal - $cuisine, Price: $price, Difficulty: $difficulty)..."
  response=$(curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty\"}")

  if echo "$response" | grep -q '"status": "combatant added"'; then
    echo "Meal '$meal' added successfully."
  else
    echo "Failed to delete meal by ID ($id)."
    exit 1
  fi
}

get_meal_by_id() {
  meal_id=$1

  echo "Getting meal by ID ($meal_id)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-id/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "meal retrieved successfully by ID ($meal_id)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Song JSON (ID $meal_id):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get song by ID ($meal_id)."
    exit 1
  fi
}


# there might be an issue here w the response line
get_meal_by_id() {
  id=$1
  meal=$2
  cuisine=$3

  echo "Getting meal by id (id: '$id', meal: '$meal', cuisine: $cuisine)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-name?id=$(echo $id | sed 's/ /%20/g')&meal=$(echo $meal | sed 's/ /%20/g')&cuisine=$cuisine")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "meal retrieved successfully by id."
    if [ "$ECHO_JSON" = true ]; then
      echo "meal JSON from id:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal from id"
    exit 1
  fi
}

delete_meal_by_id() {
  meal_id=$1
  echo "Deleting meal by ID ($meal_id)..."
  response=$(curl -s -X DELETE "$BASE_URL/delete-meal/$meal_id")
  if echo "$response" | grep -q '"status": "meal deleted"'; then
    echo "Meal deleted successfully by ID ($meal_id)."
  else
    echo "Failed to battle."
    exit 1
  fi
}

############################################################
#
# Combat Management
#
############################################################

prep_combatant() {
  meal_name=$1
  
  echo "Preparing combatant with Meal name ($meal_name)..."
  response=$(curl -s -X POST "$BASE_URL/prep-combatant" \
    -H "Content-Type: application/json" \
    -d "{\"meal\": \"$meal_name\"}")
  if echo "$response" | grep -q '"status": "combatant prepared"'; then
    echo "Combatant prepared successfully."
  else
    echo "Failed to prepare combatant."
    exit 1
  fi
}

get_combatants() {
  echo "Retrieving current combatants..."
  response=$(curl -s -X GET "$BASE_URL/get-combatants")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "get-combatants successful."
  else
    echo "failed to get-combatants."
    exit 1
  fi
}

conduct_battle() {
  echo "Conducting battle between combatants..."
  response=$(curl -s -X GET "$BASE_URL/battle")
  if echo "$response" | grep -q '"status": "battle complete"'; then
    echo "Battle conducted successfully."
  else
    echo "failed to prep-combatant."
    exit 1
  fi
}

clear_combatants() {
  echo "Clearing all combatants..."
  response=$(curl -s -X POST "$BASE_URL/clear-combatants")
  if echo "$response" | grep -q '"status": "combatants cleared"'; then
    echo "Combatants cleared successfully."
  else
    echo "Failed to clear combatants."
    exit 1
  fi
}

############################################################
#
# Leaderboard
#
############################################################

# Function to get the meal leaderboard sorted by win count
get_meal_leaderboard() {
  echo "Getting meal leaderboard sorted by win count..."
  response=$(curl -s -X GET "$BASE_URL/leaderboard")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal leaderboard retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Leaderboard JSON (sorted by win count):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal leaderboard."
    exit 1
  fi
}

# # echo "complete"

# # Health checks
check_health
check_db

# Clear the catalog
# clear_catalog

# Create some meals
create_meal "Spaghetti" "Italian" 12.50 "MED"
create_meal "Sushi" "Japanese" 15.00 "HIGH"
create_meal "Taco" "Mexican" 8.00 "LOW"

# Prepare combatants
prep_combatant "Sushi"
prep_combatant "Spaghetti"

# Retrieve combatants
get_combatants

# Conduct battle
conduct_battle

# Retrieve combatants again
get_combatants

# Get leaderboard
get_meal_leaderboard

# Delete a meal
get_meal_by_id 1
delete_meal_by_id 1

# Clear all combatants
clear_combatants

echo "All tests passed successfully!"