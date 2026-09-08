import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Cricket Analytics Platform", page_icon="🏏", layout="wide")
st.title("🏏 Cricket Analytics Platform")
st.caption("P2 Match + Ball-by-Ball Analytics")

VIEWS = {
    "match": "CRICKET_ANALYTICS.SEM.V_MATCH_SUMMARY",
    "batting": "CRICKET_ANALYTICS.SEM.V_PLAYER_BATTING",
    "bowling": "CRICKET_ANALYTICS.SEM.V_PLAYER_BOWLING",
    "team": "CRICKET_ANALYTICS.SEM.V_TEAM_TRENDS",
    "venue": "CRICKET_ANALYTICS.SEM.V_VENUE_TRENDS",
    "delivery": "CRICKET_ANALYTICS.SEM.V_DELIVERY_EXPLORER",
}


def load_view(key: str) -> pd.DataFrame:
    session = get_active_session()
    rows = session.sql(f"SELECT * FROM {VIEWS[key]}").collect()
    if not rows:
        return pd.DataFrame()
    return pd.DataFrame([row.as_dict() for row in rows])


page = st.sidebar.radio("Page", ["Match Overview", "Player Insights", "Team/Venue", "Explorer"])

if page == "Match Overview":
    df = load_view("match")
    st.subheader("Match Overview")
    if df.empty:
        st.info("No match data available.")
    else:
        matches = st.sidebar.multiselect("Match", sorted(df.MATCH_ID.dropna().unique()))
        teams = st.sidebar.multiselect("Team", sorted(pd.unique(pd.concat([df.TEAM_A_ID, df.TEAM_B_ID]).dropna())))
        innings = st.sidebar.multiselect("Innings", sorted(df.INNINGS_NO.dropna().unique()))
        if matches:
            df = df[df.MATCH_ID.isin(matches)]
        if teams:
            df = df[df.TEAM_A_ID.isin(teams) | df.TEAM_B_ID.isin(teams)]
        if innings:
            df = df[df.INNINGS_NO.isin(innings)]

        c1, c2, c3, c4, c5, c6 = st.columns(6)
        c1.metric("Total Runs", int(df.TOTAL_RUNS.sum()))
        c2.metric("Wickets", int(df.WICKETS.sum()))
        c3.metric("Run Rate", round(df.RUN_RATE.mean(), 2))
        c4.metric("Boundary %", round(df.BOUNDARY_PCT.mean(), 2))
        c5.metric("Dot Ball %", round(df.DOT_BALL_PCT.mean(), 2))
        c6.metric("Extras", int(df.EXTRAS.sum()))

        st.markdown("### Run Rate by Innings")
        st.bar_chart(df.groupby("INNINGS_NO")["RUN_RATE"].mean())

        st.markdown("### Wickets Timeline")
        wickets = df.groupby("INNINGS_NO")["WICKETS"].sum()
        st.line_chart(wickets)

        st.dataframe(df, use_container_width=True)

elif page == "Player Insights":
    batting = load_view("batting")
    bowling = load_view("bowling")
    st.subheader("Player Insights")

    top_n = st.sidebar.slider("Top N players", 5, 20, 10)
    c1, c2 = st.columns(2)
    with c1:
        st.markdown("### Top Batters")
        top_bat = batting.sort_values(["RUNS", "STRIKE_RATE"], ascending=[False, False]).head(top_n)
        st.dataframe(top_bat, use_container_width=True)
        st.bar_chart(top_bat.set_index("PLAYER_NAME")["RUNS"])

    with c2:
        st.markdown("### Top Bowlers")
        top_bowl = bowling.sort_values(["WICKETS", "ECONOMY"], ascending=[False, True]).head(top_n)
        st.dataframe(top_bowl, use_container_width=True)
        st.bar_chart(top_bowl.set_index("PLAYER_NAME")["WICKETS"])

elif page == "Team/Venue":
    team = load_view("team")
    venue = load_view("venue")
    st.subheader("Team / Venue Analytics")

    st.markdown("### Team performance and winning trends")
    if not team.empty:
        st.dataframe(team, use_container_width=True)
        win_summary = team.groupby(["TEAM_NAME", "TEAM_SIDE"])["WIN_FLAG"].sum().unstack(fill_value=0)
        st.bar_chart(win_summary)

    st.markdown("### Venue leaderboard")
    if not venue.empty:
        venue_rank = venue.sort_values("RUNS", ascending=False)
        st.dataframe(venue_rank, use_container_width=True)
        st.bar_chart(venue_rank.nlargest(10, "RUNS").set_index("VENUE_ID")["RUNS"])

else:
    st.subheader("Ball-by-Ball Explorer")
    df = load_view("delivery")
    if df.empty:
        st.info("No delivery data available.")
    else:
        matches = st.sidebar.multiselect("Match", sorted(df.MATCH_ID.dropna().unique()))
        phases = st.sidebar.multiselect("Over Phase", sorted(df.OVER_PHASE.dropna().unique()))
        innings = st.sidebar.multiselect("Innings", sorted(df.INNINGS_NO.dropna().unique()))
        if matches:
            df = df[df.MATCH_ID.isin(matches)]
        if phases:
            df = df[df.OVER_PHASE.isin(phases)]
        if innings:
            df = df[df.INNINGS_NO.isin(innings)]

        st.dataframe(df, use_container_width=True)
        st.download_button(
            "Export CSV",
            df.to_csv(index=False).encode("utf-8"),
            "cricket_ball_by_ball.csv",
            "text/csv",
        )

        st.markdown("### Phase Heatmap")
        heat = df.pivot_table(index="OVER_NO", columns="OVER_PHASE", values="TOTAL_RUNS", aggfunc="sum", fill_value=0)
        st.dataframe(heat, use_container_width=True)
