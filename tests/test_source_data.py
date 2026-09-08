import pandas as pd
from pathlib import Path
ROOT=Path(__file__).parents[1]

def test_source_counts():
    assert len(pd.read_csv(ROOT/'landing/cricket_analytics/teams/cricket_teams.csv'))==15
    assert len(pd.read_csv(ROOT/'landing/cricket_analytics/players/cricket_players.csv'))==20
    assert len(pd.read_csv(ROOT/'landing/cricket_analytics/matches/cricket_matches.csv'))==15
    assert len(pd.read_csv(ROOT/'landing/cricket_analytics/deliveries/cricket_deliveries.csv'))==25

def test_delivery_business_key_unique():
    assert pd.read_csv(ROOT/'landing/cricket_analytics/deliveries/cricket_deliveries.csv')['DELIVERY_ID'].is_unique

def test_delivery_run_reconciliation():
    d=pd.read_csv(ROOT/'landing/cricket_analytics/deliveries/cricket_deliveries.csv')
    calc=d.BATSMAN_RUNS+d.WIDES+d.NO_BALLS+d.BYES+d.LEG_BYES
    assert (calc==d.TOTAL_RUNS).all()

def test_player_team_references():
    p=pd.read_csv(ROOT/'landing/cricket_analytics/players/cricket_players.csv'); t=pd.read_csv(ROOT/'landing/cricket_analytics/teams/cricket_teams.csv')
    assert p.CURRENT_TEAM_ID.isin(t.TEAM_ID).all()

def test_delivery_references():
    d=pd.read_csv(ROOT/'landing/cricket_analytics/deliveries/cricket_deliveries.csv'); m=pd.read_csv(ROOT/'landing/cricket_analytics/matches/cricket_matches.csv'); p=pd.read_csv(ROOT/'landing/cricket_analytics/players/cricket_players.csv'); t=pd.read_csv(ROOT/'landing/cricket_analytics/teams/cricket_teams.csv')
    assert d.MATCH_ID.isin(m.MATCH_ID).all(); assert d.STRIKER_PLAYER_ID.isin(p.PLAYER_ID).all(); assert d.BOWLER_PLAYER_ID.isin(p.PLAYER_ID).all(); assert d.BATTING_TEAM_ID.isin(t.TEAM_ID).all(); assert d.BOWLING_TEAM_ID.isin(t.TEAM_ID).all()
