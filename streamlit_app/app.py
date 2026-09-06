import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session


# ============================================================
# PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="Cricket Analytics",
    page_icon="🏏",
    layout="wide"
)


# ============================================================
# TITLE
# ============================================================

st.title("🏏 Cricket Analytics Dashboard")
st.caption("Snowflake-powered Cricket Analytics Platform")


# ============================================================
# SNOWFLAKE SESSION
# ============================================================

@st.cache_resource
def get_session():
    return get_active_session()


session = get_session()


# ============================================================
# LOAD DATA
# ============================================================

@st.cache_data
def load_match_summary():
    return session.sql("""
        SELECT *
        FROM CRICKET_ANALYTICS_DB.SEMANTIC.V_MATCH_SUMMARY
    """).to_pandas()


@st.cache_data
def load_player_batting():
    return session.sql("""
        SELECT *
        FROM CRICKET_ANALYTICS_DB.SEMANTIC.V_PLAYER_BATTING
    """).to_pandas()


@st.cache_data
def load_player_bowling():
    return session.sql("""
        SELECT *
        FROM CRICKET_ANALYTICS_DB.SEMANTIC.V_PLAYER_BOWLING
    """).to_pandas()


@st.cache_data
def load_team_trends():
    return session.sql("""
        SELECT *
        FROM CRICKET_ANALYTICS_DB.SEMANTIC.V_TEAM_TRENDS
    """).to_pandas()


# ============================================================
# FETCH DATA
# ============================================================

matches = load_match_summary()
batting = load_player_batting()
bowling = load_player_bowling()
teams = load_team_trends()


# ============================================================
# KPI SECTION
# ============================================================

total_matches = matches["MATCH_ID"].nunique()
total_runs = int(matches["TOTAL_RUNS"].sum())
total_wickets = int(matches["WICKETS"].sum())
total_sixes = int(matches["SIXES"].sum())


col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric(
        "Total Matches",
        total_matches
    )

with col2:
    st.metric(
        "Total Runs",
        total_runs
    )

with col3:
    st.metric(
        "Total Wickets",
        total_wickets
    )

with col4:
    st.metric(
        "Total Sixes",
        total_sixes
    )


st.divider()


# ============================================================
# MATCH ANALYTICS
# ============================================================

st.header("📊 Match Analytics")

col1, col2 = st.columns(2)

with col1:

    st.subheader("Runs by Match")

    match_runs = (
        matches
        .sort_values("TOTAL_RUNS", ascending=False)
        .head(10)
    )

    st.bar_chart(
        match_runs.set_index("MATCH_ID")["TOTAL_RUNS"]
    )


with col2:

    st.subheader("Wickets by Match")

    match_wickets = (
        matches
        .sort_values("WICKETS", ascending=False)
        .head(10)
    )

    st.bar_chart(
        match_wickets.set_index("MATCH_ID")["WICKETS"]
    )


# ============================================================
# PLAYER BATTING
# ============================================================

st.divider()

st.header("🏏 Player Batting")

top_batters = (
    batting
    .sort_values("RUNS", ascending=False)
    .head(10)
)

st.dataframe(
    top_batters[
        [
            "PLAYER_ID",
            "FIRST_NAME",
            "LAST_NAME",
            "ROLE",
            "RUNS",
            "BALLS",
            "FOURS",
            "SIXES"
        ]
    ],
    use_container_width=True
)


# ============================================================
# PLAYER BOWLING
# ============================================================

st.header("🎯 Player Bowling")

top_bowlers = (
    bowling
    .sort_values(
        ["WICKETS", "RUNS_CONCEDED"],
        ascending=[False, True]
    )
    .head(10)
)

st.dataframe(
    top_bowlers[
        [
            "PLAYER_ID",
            "FIRST_NAME",
            "LAST_NAME",
            "ROLE",
            "WICKETS",
            "RUNS_CONCEDED",
            "BALLS_BOWLED"
        ]
    ],
    use_container_width=True
)


# ============================================================
# TEAM PERFORMANCE
# ============================================================

st.divider()

st.header("🏆 Team Performance")

team_chart = (
    teams
    .sort_values("WINS", ascending=False)
    .head(10)
)

st.bar_chart(
    team_chart.set_index("TEAM_NAME")["WINS"]
)


# ============================================================
# MATCH DETAILS
# ============================================================

st.divider()

st.header("📋 Match Details")

st.dataframe(
    matches[
        [
            "MATCH_ID",
            "COMPETITION",
            "FORMAT",
            "MATCH_DATE",
            "TEAM_A_ID",
            "TEAM_B_ID",
            "WINNER_TEAM_ID",
            "TOTAL_RUNS",
            "WICKETS",
            "FOURS",
            "SIXES"
        ]
    ].sort_values(
        "MATCH_DATE",
        ascending=False
    ),
    use_container_width=True
)


# ============================================================
# FOOTER
# ============================================================

st.divider()

st.caption(
    "Cricket Analytics | Snowflake + dbt + Snowpark + Streamlit"
)