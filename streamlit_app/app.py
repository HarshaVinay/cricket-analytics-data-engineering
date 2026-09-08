import streamlit as st
import pandas as pd

st.set_page_config(page_title="Cricket Analytics Platform", page_icon="🏏", layout="wide")
st.title("🏏 Cricket Analytics Platform")
st.caption("P2 Match + Ball-by-Ball Analytics")

@st.cache_data(ttl=300)
def load_view(view_name: str) -> pd.DataFrame:
    conn = st.connection("snowflake")
    return conn.query(f"SELECT * FROM {view_name}", ttl=300)

page = st.sidebar.radio("Page", ["Match Overview", "Player Insights", "Team/Venue", "Explorer"])

if page == "Match Overview":
    df = load_view("CRICKET_ANALYTICS.SEM.V_MATCH_SUMMARY")
    st.subheader("Match Overview")
    if df.empty:
        st.info("No match data available.")
    else:
        matches = st.sidebar.multiselect("Match", sorted(df.MATCH_ID.dropna().unique()))
        teams = st.sidebar.multiselect("Team", sorted(pd.unique(pd.concat([df.TEAM_A_ID, df.TEAM_B_ID]).dropna())))
        innings = st.sidebar.multiselect("Innings", sorted(df.INNINGS_NO.dropna().unique()))
        if matches: df = df[df.MATCH_ID.isin(matches)]
        if teams: df = df[df.TEAM_A_ID.isin(teams) | df.TEAM_B_ID.isin(teams)]
        if innings: df = df[df.INNINGS_NO.isin(innings)]
        c1,c2,c3,c4,c5,c6 = st.columns(6)
        c1.metric("Total Runs", int(df.TOTAL_RUNS.sum()))
        c2.metric("Wickets", int(df.WICKETS.sum()))
        c3.metric("Run Rate", round(df.RUN_RATE.mean(), 2))
        c4.metric("Boundary %", round(df.BOUNDARY_PCT.mean(), 2))
        c5.metric("Dot Ball %", round(df.DOT_BALL_PCT.mean(), 2))
        c6.metric("Extras", int(df.EXTRAS.sum()))
        st.markdown("### Run Rate by Innings")
        st.bar_chart(df.groupby("INNINGS_NO")["RUN_RATE"].mean())

elif page == "Player Insights":
    batting = load_view("CRICKET_ANALYTICS.SEM.V_PLAYER_BATTING")
    bowling = load_view("CRICKET_ANALYTICS.SEM.V_PLAYER_BOWLING")
    st.subheader("Player Insights")
    c1,c2 = st.columns(2)
    with c1:
        st.markdown("### Top Batters")
        st.dataframe(batting.sort_values("RUNS", ascending=False).head(10), use_container_width=True)
        st.bar_chart(batting.nlargest(10, "RUNS").set_index("PLAYER_NAME")["RUNS"])
    with c2:
        st.markdown("### Top Bowlers")
        st.dataframe(bowling.sort_values(["WICKETS", "ECONOMY"], ascending=[False, True]).head(10), use_container_width=True)
        st.bar_chart(bowling.nlargest(10, "WICKETS").set_index("PLAYER_NAME")["WICKETS"])

elif page == "Team/Venue":
    team = load_view("CRICKET_ANALYTICS.SEM.V_TEAM_TRENDS")
    venue = load_view("CRICKET_ANALYTICS.SEM.V_VENUE_TRENDS")
    st.subheader("Team / Venue Analytics")
    st.markdown("### Team performance")
    st.dataframe(team, use_container_width=True)
    st.markdown("### Venue leaderboard")
    st.dataframe(venue.sort_values("RUNS", ascending=False), use_container_width=True)
    st.bar_chart(venue.nlargest(10, "RUNS").set_index("VENUE_ID")["RUNS"])

else:
    st.subheader("Ball-by-Ball Explorer")
    df = load_view("CRICKET_ANALYTICS.SEM.V_DELIVERY_EXPLORER")
    if df.empty:
        st.info("No delivery data available.")
    else:
        matches = st.sidebar.multiselect("Match", sorted(df.MATCH_ID.dropna().unique()))
        phases = st.sidebar.multiselect("Over Phase", sorted(df.OVER_PHASE.dropna().unique()))
        if matches: df = df[df.MATCH_ID.isin(matches)]
        if phases: df = df[df.OVER_PHASE.isin(phases)]
        st.dataframe(df, use_container_width=True)
        st.download_button("Export CSV", df.to_csv(index=False).encode("utf-8"), "cricket_ball_by_ball.csv", "text/csv")
