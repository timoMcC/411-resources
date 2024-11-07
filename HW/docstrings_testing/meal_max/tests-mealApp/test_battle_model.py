import pytest

from meal_max.models.battle_model import BattleModel
from meal_max.models.kitchen_model import Meal


@pytest.fixture()
def battle_model():
    """Fixture to provide a new instance of BattleModel for each test."""
    return BattleModel()

"""Fixtures providing sample meals for the tests."""
@pytest.fixture
def sample_meal1():
    """Fixture for a sample Meal instance."""
    return Meal(id=1, meal='Spaghetti', price=12.50, cuisine=['Italian'], difficulty='MED')


@pytest.fixture
def sample_meal2():
    """Fixture for another sample Meal instance."""
    return Meal(id=2, meal='Sushi', price=15.00, cuisine=['Japanese'], difficulty='HIGH')

@pytest.fixture
def sample_meal3():
    """Fixture for a third sample Meal instance."""
    return Meal(id=3, meal='Tacos', price=8.00, cuisine=['Mexican'], difficulty='LOW')

@pytest.fixture
def sample_battle_model(sample_meal1, sample_meal2):
    return [sample_meal1, sample_meal2]



##################################################
# Prep Combatant Test Cases
##################################################

def test_add_meal_to_battle(battle_model, sample_meal1):
    """Test adding a meal to the battle."""
    battle_model.prep_combatant(sample_meal1)
    assert len(battle_model.combatants) == 1
    assert battle_model.combatants[0].meal == 'Spaghetti'

def test_prep_combatant_full(battle_model, sample_meal1, sample_meal2, sample_meal3):
    """Test adding a meal when the combatants list is full."""
    battle_model.prep_combatant(sample_meal1)
    battle_model.prep_combatant(sample_meal2)
    with pytest.raises(ValueError, match="Combatant list is full"):
        battle_model.prep_combatant(sample_meal3)

def test_prep_combatant_invalid_data(battle_model):
    """Test adding a combatant with invalid data."""
    invalid_meal = "Not a meal"
    with pytest.raises(AttributeError):
        battle_model.prep_combatant(invalid_meal)

##################################################
# Clear Combatants Test Cases
##################################################

def test_clear_combatants(battle_model, sample_meal1, sample_meal2):
    """Test clearing all combatants from battle."""
    battle_model.prep_combatant(sample_meal1)
    battle_model.prep_combatant(sample_meal2)
    assert len(battle_model.combatants) == 2

    battle_model.clear_combatants()
    assert len(battle_model.combatants) == 0


##################################################
# Get Battle Score Test Cases
##################################################

def test_get_battle_score(battle_model, sample_meal1):
    """Test calculating battle score for a combatant."""
    score = battle_model.get_battle_score(sample_meal1)
    expected = (sample_meal1.price * len(sample_meal1.cuisine)) - {"HIGH": 1, "MED": 2, "LOW": 3}[sample_meal1.difficulty]
    assert score == expected


def test_get_battle_score_invalid_diff(battle_model, sample_meal1):
    """Test that get_battle_score raises KeyError for invalid difficulty."""
    sample_meal1.difficulty = 'not valid'
    with pytest.raises(KeyError):
        battle_model.get_battle_score(sample_meal1)

##################################################
# Get Combatants Test Cases
##################################################

def test_get_combatants(battle_model, sample_meal1, sample_meal2):
    """Test retrieving the list of combatants."""
    battle_model.prep_combatant(sample_meal1)
    battle_model.prep_combatant(sample_meal2)
    combatants = battle_model.get_combatants()
    assert combatants == [sample_meal1, sample_meal2]