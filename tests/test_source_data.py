import pandas as pd
from pathlib import Path

ROOT = Path(__file__).parents[1]


def load(entity):
    return pd.read_csv(ROOT / f"landing/cricket_analytics/{entity}/cricket_{entity}.csv")


def test_source_counts():
    assert len(load("teams")) == 15
    assert len(load("players")) == 20
    assert len(load("matches")) == 15
    assert len(load("deliveries")) == 25


def test_business_keys_unique():
    assert load("teams")["TEAM_ID"].is_unique
    assert load("players")["PLAYER_ID"].is_unique
    assert load("matches")["MATCH_ID"].is_unique
    assert load("deliveries")["DELIVERY_ID"].is_unique


def test_delivery_run_reconciliation():
    d = load("deliveries")
    calc = d.BATSMAN_RUNS + d.WIDES + d.NO_BALLS + d.BYES + d.LEG_BYES
    assert (calc == d.TOTAL_RUNS).all()


def test_player_team_references():
    p, t = load("players"), load("teams")
    assert p.CURRENT_TEAM_ID.isin(t.TEAM_ID).all()


def test_match_references():
    m, t = load("matches"), load("teams")
    assert m.TEAM_A_ID.isin(t.TEAM_ID).all()
    assert m.TEAM_B_ID.isin(t.TEAM_ID).all()
    assert m.TOSS_WINNER_TEAM_ID.isin(t.TEAM_ID).all()
    assert m.WINNER_TEAM_ID.isin(t.TEAM_ID).all()


def test_delivery_references():
    d = load("deliveries")
    m, p, t = load("matches"), load("players"), load("teams")
    assert d.MATCH_ID.isin(m.MATCH_ID).all()
    assert d.STRIKER_PLAYER_ID.isin(p.PLAYER_ID).all()
    assert d.NON_STRIKER_PLAYER_ID.isin(p.PLAYER_ID).all()
    assert d.BOWLER_PLAYER_ID.isin(p.PLAYER_ID).all()
    assert d.BATTING_TEAM_ID.isin(t.TEAM_ID).all()
    assert d.BOWLING_TEAM_ID.isin(t.TEAM_ID).all()


def test_delivery_event_flags_are_binary():
    d = load("deliveries")
    for col in ["IS_WICKET", "IS_FOUR", "IS_SIX", "IS_DOT_BALL"]:
        assert set(d[col].dropna().unique()).issubset({0, 1})


def test_delivery_numeric_fields_non_negative():
    d = load("deliveries")
    for col in ["BATSMAN_RUNS", "WIDES", "NO_BALLS", "BYES", "LEG_BYES", "TOTAL_RUNS"]:
        assert (d[col].fillna(0) >= 0).all()
