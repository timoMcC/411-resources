from contextlib import contextmanager
import re
import sqlite3

import pytest

from meal_max.models.kitchen_model import (
    Meal,
    create_meal,
    delete_meal,
    get_meal_by_id,
    get_meal_by_name,
    update_meal_stats
)

######################################################
#
#    Fixtures
#
######################################################

def normalize_whitespace(sql_query: str) -> str:
    return re.sub(r'\s+', ' ', sql_query).strip()

# Mocking the database connection for tests
@pytest.fixture
def mock_cursor(mocker):
    mock_conn = mocker.Mock()
    mock_cursor = mocker.Mock()

    # Mock the connection's cursor
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchone.return_value = None  # Default return for queries
    mock_cursor.fetchall.return_value = []
    mock_cursor.commit.return_value = None

    # Mock the get_db_connection context manager from sql_utils
    @contextmanager
    def mock_get_db_connection():
        yield mock_conn  # Yield the mocked connection object

    mocker.patch("meal_max.models.kitchen_model.get_db_connection", mock_get_db_connection)

    return mock_cursor  # Return the mock cursor so we can set expectations per test

# ######################################################
# #
# #    Add and delete meals
# #
# ######################################################

def test_create_meal(mock_cursor):
    """Test creating a new meal in the kitchen."""

    # Call the function to create a new meal
    create_meal(meal ="Pizza",cuisine="Italian",price =10.0,difficulty="MED")

    expected_query = normalize_whitespace("""
        INSERT INTO meals (meal, cuisine, price, difficulty)
        VALUES (?, ?, ?, ?)
    """)

    actual_query = normalize_whitespace(mock_cursor.execute.call_args[0][0])

    # Assert that the SQL query was correct
    assert expected_query.strip() == actual_query, "The SQL query did not match the expected structure."

    # Extract the arguments used in the SQL call (second element of call_args)
    actual_arguments = mock_cursor.execute.call_args[0][1]

    # Assert that the SQL query was executed with the correct arguments
    expected_arguments = ("Pizza", "Italian", 10.0, "MED")
    assert actual_arguments == expected_arguments, f"The SQL query arguments did not match. Expected {expected_arguments}, got {actual_arguments}"

def test_create_meal_invalid_price(mock_cursor):
    """Test error when creating a meal with an invalid price (negative price)."""

    # Expect a ValueError when trying to create a meal with a negative price
    with pytest.raises(ValueError, match='Invalid price: -10.5. Price must be a positive number.'):
        create_meal(meal="Spaghetti Bolognese", cuisine="Italian", price=-10.50, difficulty="MED")

def test_create_meal_invalid_difficulty(mock_cursor):
    """Test error when creating a meal with an invalid difficulty level."""

    # Expect a ValueError when the difficulty level is invalid
    with pytest.raises(ValueError, match="Invalid difficulty level: EXTREME. Must be 'LOW', 'MED', or 'HIGH'."):
        create_meal(meal="Spaghetti Bolognese", cuisine="Italian", price=12.50, difficulty="EXTREME")

def test_delete_meal(mock_cursor):
    """Test deleting a meal from the kitchen by meal ID."""

    # Simulate that the meal exists (id = 1)
    mock_cursor.fetchone.return_value = ([False])

    # Call the delete_meal function
    delete_meal(1)

    # Normalize the SQL for both queries (SELECT and UPDATE)
    expected_select_sql = normalize_whitespace("SELECT deleted FROM meals WHERE id = ?")
    expected_update_sql = normalize_whitespace("UPDATE meals SET deleted = TRUE WHERE id = ?")

    # Access both calls to execute() using call_args_list
    actual_select_sql = normalize_whitespace(mock_cursor.execute.call_args_list[0][0][0])
    actual_update_sql = normalize_whitespace(mock_cursor.execute.call_args_list[1][0][0])

    # Ensure the correct SQL queries were executed
    assert actual_select_sql == expected_select_sql, "The SELECT query did not match the expected structure."
    assert actual_update_sql == expected_update_sql, "The UPDATE query did not match the expected structure."

    # Ensure the correct arguments were used in both SQL queries
    expected_select_args = (1,)
    expected_update_args = (1,)

    actual_select_args = mock_cursor.execute.call_args_list[0][0][1]
    actual_update_args = mock_cursor.execute.call_args_list[1][0][1]

    assert actual_select_args == expected_select_args, f"The SELECT query arguments did not match. Expected {expected_select_args}, got {actual_select_args}."
    assert actual_update_args == expected_update_args, f"The UPDATE query arguments did not match. Expected {expected_update_args}, got {actual_update_args}."

def test_delete_meal_not_found(mock_cursor):
    """Test error when trying to delete a non-existent meal."""

    # Simulate that no meal exists with the given ID
    mock_cursor.fetchone.return_value = None

    # Expect a ValueError when attempting to delete a non-existent meal
    with pytest.raises(ValueError, match="Meal with ID 999 not found"):
        delete_meal(999)

def test_delete_meal_already_deleted(mock_cursor):
    """Test error when trying to delete a meal that's already marked as deleted."""

    # Simulate that the meal exists but is already marked as deleted
    mock_cursor.fetchone.return_value = ([True])

    # Expect a ValueError when attempting to delete a meal that's already been deleted
    with pytest.raises(ValueError, match='Meal with ID 999 has been deleted'):
        delete_meal(999)

######################################################
#
#    Get Meal
#
######################################################

def test_get_meal_by_id(mock_cursor):
    """Test retrieving a meal by its ID."""

    # Simulate that the meal exists (id = 1)
    mock_cursor.fetchone.return_value = (1, "Spaghetti Bolognese", "Italian", 12.50, "MED", False)

    # Call the function and check the result
    result = get_meal_by_id(1)

    # Expected result based on the simulated fetchone return value
    expected_result = Meal(1, "Spaghetti Bolognese", "Italian", 12.50, "MED")

    # Ensure the result matches the expected output
    assert result == expected_result, f"Expected {expected_result}, got {result}"


def test_get_meal_by_id_not_found(mock_cursor):
    """Test error when trying to retrieve a meal that doesn't exist."""

    # Simulate that no meal exists for the given ID
    mock_cursor.fetchone.return_value = None

    # Expect a ValueError when the meal is not found
    with pytest.raises(ValueError, match="Meal with ID 999 not found"):
        get_meal_by_id(999)

def test_get_meal_by_name(mock_cursor):
    """Test retrieving a meal by its name."""

    # Simulate that the meal exists (name = "Spaghetti Bolognese")
    mock_cursor.fetchone.return_value = (1, "Spaghetti Bolognese", "Italian", 12.50, "MED", False)

    # Call the function and check the result
    result = get_meal_by_name("Spaghetti Bolognese")

    # Expected result based on the simulated fetchone return value
    expected_result = Meal(1, "Spaghetti Bolognese", "Italian", 12.50, "MED")

    # Ensure the result matches the expected output
    assert result == expected_result, f"Expected {expected_result}, got {result}"

def test_get_meal_by_name_not_found(mock_cursor):
    """Test error when trying to retrieve a meal that doesn't exist by name."""

    # Simulate that no meal exists with the given name
    mock_cursor.fetchone.return_value = None

    # Expect a ValueError when the meal is not found
    with pytest.raises(ValueError, match='Meal with name Spaghetti Bolognese not found'):
        get_meal_by_name("Spaghetti Bolognese")

######################################################
#
#    Update meal stats
#
######################################################

def test_update_meal_stats(mock_cursor):
    """Test updating meal statistics such as price and difficulty."""

    mock_cursor.fetchone.return_value = (False,) 

    # Call the function to update the meal stats
    update_meal_stats(meal_id=1, result='win')

    expected_query = normalize_whitespace("""
        UPDATE meals
        SET battles = battles + 1, wins = wins + 1
        WHERE id = ?
    """)
    
    actual_query = normalize_whitespace(mock_cursor.execute.call_args[0][0])
    assert actual_query == expected_query, "The SQL query did not match the expected structure."
    actual_arguments = mock_cursor.execute.call_args[0][1]
    expected_arguments = (1,)  
    assert actual_arguments == expected_arguments, f"The SQL query arguments did not match. Expected {expected_arguments}, got {actual_arguments}"
