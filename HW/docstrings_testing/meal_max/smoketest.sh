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

create_meal() {
  id=$1
  meal=$2
  cuisine=$3
  price=$4
  difficulty=$5

  echo "Adding meal -> $id , $meal, $cuisine, $price, $difficulty ..."
  curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"id\":\"$id\", \"meal\":\"$meal\", \"cuisine\":$cuisine, \"price\":\"$price\", \"difficulty\":$difficulty}" | grep -q '"status": "combatant added"'

  if [ $? -eq 0 ]; then
    echo "meal added successfully."
  else
    echo "Failed to add meal."
    exit 1
  fi
}


delete_meal_by_id() {
  id=$1

  echo "Deleting meal by ID ($id)..."
  response=$(curl -s -X DELETE "$BASE_URL/delete-meal/$id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "meal deleted successfully by ID ($id)."
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

# THIS COULD BE update_meal_stats but there is no path in app.py
# get_random_song() {
#   echo "Getting a random song from the catalog..."
#   response=$(curl -s -X GET "$BASE_URL/get-random-song")
#   if echo "$response" | grep -q '"status": "success"'; then
#     echo "Random song retrieved successfully."
#     if [ "$ECHO_JSON" = true ]; then
#       echo "Random Song JSON:"
#       echo "$response" | jq .
#     fi
#   else
#     echo "Failed to get a random song."
#     exit 1
#   fi
# }


# ############################################################
# #
# # Battle
# #
# ############################################################

battle() {
  echo "battle..."
  response=$(curl -s -X POST "$BASE_URL/battle")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "battle successful."
  else
    echo "Failed to battle."
    exit 1
  fi
}

clear_combatants() {
  echo "clear combatants..."
  response=$(curl -s -X POST "$BASE_URL/clear-combatants")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "clear-combatants successful."
  else
    echo "Failed to clear-combatants."
    exit 1
  fi
}

get_combatants() {
  echo "get combatants..."
  response=$(curl -s -X POST "$BASE_URL/get-combatants")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "get-combatants successful."
  else
    echo "failed to get-combatants."
    exit 1
  fi
}

prep_combatants() {
  echo "prep combatants..."
  response=$(curl -s -X POST "$BASE_URL/prep-combatant")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "prep-combatant successful."
  else
    echo "failed to prep-combatant."
    exit 1
  fi
}

# ############################################################
# #
# # Leaderboard
# #
# ############################################################

# get_leaderboard() {
#   echo "getting leaderboard..."
#   response=$(curl -s -X POST "$BASE_URL/leaderboard")

#   if echo "$response" | grep -q '"status": "success"'; then
#     echo "get leaderboard."
#   else
#     echo "Failed to get leaderboard."
#     exit 1
#   fi
# }

# # echo "complete"

# # Health checks
check_health
check_db

# # Create songs
create_meal 111 "test1" "test1" 20.0 "LOW"
# create_meal 101 "pasta1" "italia1n" 201.0 "LOW"
# create_meal 102 "pasta2" "italian2" 201.0 "LOW"
# create_meal 103 "past3" "italian3" 200.0 "HIGH"

# delete_song_by_id 1
# get_all_songs

# get_song_by_id 2
# get_song_by_compound_key "The Beatles" "Let It Be" 1970
# get_random_song

# add_song_to_playlist "The Rolling Stones" "Paint It Black" 1966
# add_song_to_playlist "Queen" "Bohemian Rhapsody" 1975
# add_song_to_playlist "Led Zeppelin" "Stairway to Heaven" 1971
# add_song_to_playlist "The Beatles" "Let It Be" 1970

# remove_song_from_playlist "The Beatles" "Let It Be" 1970
# remove_song_by_track_number 2

# get_all_songs_from_playlist

# add_song_to_playlist "Queen" "Bohemian Rhapsody" 1975
# add_song_to_playlist "The Beatles" "Let It Be" 1970

# move_song_to_beginning "The Beatles" "Let It Be" 1970
# move_song_to_end "Queen" "Bohemian Rhapsody" 1975
# move_song_to_track_number "Led Zeppelin" "Stairway to Heaven" 1971 2
# swap_songs_in_playlist 1 2

# get_all_songs_from_playlist
# get_song_from_playlist_by_track_number 1

# get_playlist_length_duration

# play_current_song
# rewind_playlist

# play_entire_playlist
# play_current_song
# play_rest_of_playlist

# get_song_leaderboard

echo "All tests passed successfully!"