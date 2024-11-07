import pytest
from meal_max.models.kitchen_model import Meal, create_meal, delete_meal, get_leaderboard, get_meal_by_id, get_meal_by_name, update_meal_stats
import sqlite3

@pytest.fixture()
def mock_create_meal():
    """Mock the create_meal function for testing."""
    return create_meal

@pytest.fixture()
def sample_meal():
    """Fixture to provide a sample meal instance."""
    return Meal(id=1, meal="Spaghetti", cuisine="Italian", price=10, difficulty="MED")

@pytest.fixture()
def sample_meal_invalid():
    """Fixture to provide an invalid sample meal with negative price."""
    return Meal(id=1, meal="Spaghetti", cuisine="Italian", price=-10, difficulty="MED")

@pytest.fixture()
def sample_meal_without_difficulty():
    """Fixture to provide a sample meal with invalid difficulty."""
    return Meal(id=1, meal="Spaghetti", cuisine="Italian", price=10, difficulty="INVALID")

##################################################
# Create Meal Test Cases
##################################################

def test_create_meal(mock_create_meal):
    """Test creating a valid meal."""
    try:
        mock_create_meal("Pizza", "Italian", 12.99, "LOW")
    except ValueError:
        pytest.fail("create_meal raised ValueError unexpectedly")
    
def test_create_meal_invalid_price(mock_create_meal):
    """Test creating a meal with invalid price."""
    with pytest.raises(ValueError, match="Invalid price: -10.0. Price must be a positive number."):
        mock_create_meal("Pizza", "Italian", -10.0, "LOW")

def test_create_meal_invalid_difficulty(mock_create_meal):
    """Test creating a meal with invalid difficulty."""
    with pytest.raises(ValueError, match="Invalid difficulty level: INVALID. Must be 'LOW', 'MED', or 'HIGH'."):
        mock_create_meal("Pizza", "Italian", 12.99, "INVALID")

def test_create_duplicate_meal(mock_create_meal):
    """Test creating a meal that already exists (duplicate meal)."""
    mock_create_meal("Pizza", "Italian", 12.99, "LOW")
    with pytest.raises(ValueError, match="Meal with name 'Pizza' already exists"):
        mock_create_meal("Pizza", "Italian", 15.99, "MED")

##################################################
# Delete Meal Test Cases
##################################################

def test_delete_meal(sample_meal):
    """Test soft deleting a meal."""
    delete_meal(sample_meal.id)
    
    with pytest.raises(ValueError, match=f"Meal with ID {sample_meal.id} has been deleted"):
        get_meal_by_id(sample_meal.id)

def test_delete_nonexistent_meal():
    """Test deleting a non-existent meal."""
    with pytest.raises(ValueError, match="Meal with ID 999 not found"):
        delete_meal(999)

def test_delete_already_deleted_meal(sample_meal):
    """Test deleting a meal that has already been deleted."""
    delete_meal(sample_meal.id)  # First delete
    with pytest.raises(ValueError, match=f"Meal with ID {sample_meal.id} has been deleted"):
        delete_meal(sample_meal.id)  # Attempt to delete again

##################################################
# Get Meal by ID Test Cases
##################################################

def test_get_meal_by_id(sample_meal):
    """Test getting a meal by ID."""
    meal = get_meal_by_id(sample_meal.id)
    assert meal.id == sample_meal.id
    assert meal.meal == sample_meal.meal
    assert meal.cuisine == sample_meal.cuisine
    assert meal.price == sample_meal.price
    assert meal.difficulty == sample_meal.difficulty

def test_get_non_existent_meal_by_id():
    """Test trying to get a meal that does not exist by ID."""
    with pytest.raises(ValueError, match="Meal with ID 999 not found"):
        get_meal_by_id(999)

def test_get_deleted_meal_by_id(sample_meal):
    """Test trying to get a deleted meal by ID."""
    delete_meal(sample_meal.id)
    with pytest.raises(ValueError, match=f"Meal with ID {sample_meal.id} has been deleted"):
        get_meal_by_id(sample_meal.id)

##################################################
# Get Meal by Name Test Cases
##################################################

def test_get_meal_by_name(sample_meal):
    """Test getting a meal by name."""
    meal = get_meal_by_name(sample_meal.meal)
    assert meal.id == sample_meal.id
    assert meal.meal == sample_meal.meal
    assert meal.cuisine == sample_meal.cuisine
    assert meal.price == sample_meal.price
    assert meal.difficulty == sample_meal.difficulty

def test_get_non_existent_meal_by_name():
    """Test trying to get a meal that does not exist by name."""
    with pytest.raises(ValueError, match="Meal with name NonExistentMeal not found"):
        get_meal_by_name("NonExistentMeal")

def test_get_deleted_meal_by_name(sample_meal):
    """Test trying to get a deleted meal by name."""
    delete_meal(sample_meal.id)
    with pytest.raises(ValueError, match=f"Meal with name {sample_meal.meal} has been deleted"):
        get_meal_by_name(sample_meal.meal)

##################################################
# Update Meal Stats Test Cases
##################################################

def test_update_meal_stats_win(sample_meal):
    """Test updating a meal's stats with a win."""
    update_meal_stats(sample_meal.id, "win")
    meal = get_meal_by_id(sample_meal.id)
    assert meal.wins == 1
    assert meal.battles == 1

def test_update_meal_stats_loss(sample_meal):
    """Test updating a meal's stats with a loss."""
    update_meal_stats(sample_meal.id, "loss")
    meal = get_meal_by_id(sample_meal.id)
    assert meal.wins == 0
    assert meal.battles == 1

def test_update_meal_stats_invalid_result(sample_meal):
    """Test updating meal stats with an invalid result."""
    with pytest.raises(ValueError, match="Invalid result: invalid. Expected 'win' or 'loss'."):
        update_meal_stats(sample_meal.id, "invalid")

def test_update_non_existent_meal_stats():
    """Test updating stats for a non-existent meal."""
    with pytest.raises(ValueError, match="Meal with ID 999 not found"):
        update_meal_stats(999, "win")

##################################################
# Leaderboard Test Cases
##################################################

def test_get_leaderboard_by_wins():
    """Test retrieving the leaderboard sorted by wins."""
    leaderboard = get_leaderboard("wins")
    assert isinstance(leaderboard, list)
    assert leaderboard[0]['wins'] >= leaderboard[1]['wins']

def test_get_leaderboard_by_win_pct():
    """Test retrieving the leaderboard sorted by win percentage."""
    leaderboard = get_leaderboard("win_pct")
    assert isinstance(leaderboard, list)
    assert leaderboard[0]['win_pct'] >= leaderboard[1]['win_pct']

def test_get_leaderboard_invalid_sort_by():
    """Test retrieving leaderboard with invalid sort_by argument."""
    with pytest.raises(ValueError, match="Invalid sort_by parameter: invalid"):
        get_leaderboard("invalid")
