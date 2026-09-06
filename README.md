# 🏏 Cricket Analytics Data Engineering Platform

A complete end-to-end Cricket Analytics data engineering platform built using
Snowflake, dbt, Snowpark Python, Streamlit, and Git.

---

## 📌 Project Overview

The Cricket Analytics platform ingests cricket data into Snowflake and
transforms it into an analytical data warehouse using a star schema.

The platform supports:

- Match analytics
- Player batting analytics
- Player bowling analytics
- Team performance analytics
- Delivery-level analysis
- Data quality validation
- Incremental processing
- Slowly Changing Dimensions
- Snowpark transformations
- Streamlit dashboards

---

## 🏗️ Architecture

```text
                    Cricket CSV Data
                           │
                           ▼
                  Snowflake Internal Stage
                           │
                           ▼
                     RAW Layer
                           │
                 ┌─────────┴─────────┐
                 │                   │
             COPY INTO            Snowpipe
                 │                   │
                 └─────────┬─────────┘
                           ▼
                    Data Warehouse
                           │
                    Star Schema
                           │
              ┌────────────┴────────────┐
              │                         │
          Dimensions                 Fact Table
              │                         │
              └────────────┬────────────┘
                           ▼
                     dbt Transformations
                           │
                ┌──────────┴──────────┐
                │                     │
          Incremental Models       Snapshots
                │                     │
                └──────────┬──────────┘
                           ▼
                    Semantic Layer
                           │
                           ▼
                  Streamlit Dashboard
🛠️ Technologies
Technology	Purpose
Snowflake	Cloud data warehouse
Snowflake Stage	Data ingestion
Snowpipe	Continuous ingestion demonstration
Streams	Change tracking
Tasks	Automated processing
SQL UDF	Reusable SQL calculation
Python UDF	Python-based calculation
Stored Procedure	Procedural processing
Snowpark	Python data transformation
dbt	Transformation, testing and documentation
Streamlit	Analytics dashboard
Git	Version control
📂 Project Structure
cricket_analytics/
│
├── models/
│   ├── staging/
│   └── marts/
│
├── snapshots/
│
├── tests/
│
├── macros/
│
├── analyses/
│
├── seeds/
│
├── streamlit_app/
│   └── app.py
│
├── dbt_project.yml
├── .gitignore
└── README.md
📊 Source Data

The platform works with four cricket datasets:

Teams

Contains team information such as:

Team ID
Team name
Country
Competition
Region
Established date
Status
Players

Contains:

Player ID
Name
Nationality
Batting style
Bowling style
Role
Current team
Contract information
Status
Matches

Contains:

Match ID
Competition
Format
Match date
Venue
Teams
Toss information
Winner
Result
Deliveries

Contains ball-level information including:

Match
Innings
Over
Ball
Batting team
Bowling team
Striker
Bowler
Runs
Extras
Wickets
Fours
Sixes
Dot balls
🏢 Snowflake Data Model
RAW Layer
RAW_TEAMS
RAW_PLAYERS
RAW_MATCHES
RAW_DELIVERIES
DW Layer
DIM_DATE
DIM_TEAM
DIM_VENUE
DIM_PLAYER
DIM_MATCH
FACT_DELIVERY

FACT_DELIVERY represents the delivery-level fact table, with one row
representing one cricket delivery.

🔄 SCD Type 2

DIM_PLAYER implements Slowly Changing Dimension Type 2 using:

EFFECTIVE_FROM
EFFECTIVE_TO
IS_CURRENT
UPDATED_AT

This allows historical player changes to be maintained.

⚙️ dbt Implementation

The dbt project contains:

Sources

Four Snowflake RAW sources:

raw_teams
raw_players
raw_matches
raw_deliveries
Staging Models
stg_teams
stg_players
stg_matches
stg_deliveries
Mart Models
fct_match_analytics
mart_player_batting
fct_deliveries_incremental
Snapshot
snap_players
Data Tests

The project contains tests for:

Not-null constraints
Unique keys
Referential relationships
🧪 dbt Validation

The project has been successfully validated using:

dbt build

Result:

PASS = 20
WARN = 0
ERROR = 0
SKIP = 0
TOTAL = 20

The data tests were also executed independently:

PASS = 12
WARN = 0
ERROR = 0
SKIP = 0
TOTAL = 12
🧮 Snowflake Programming

The project demonstrates:

SQL UDF
CALCULATE_STRIKE_RATE
Python UDF
CALCULATE_ECONOMY_RATE
Stored Procedure
PROCESS_PLAYER_CHANGES
Snowpark
BUILD_OVER_SUMMARY
🔐 Security

The platform includes:

Role-based access control
Analyst role
ETL role
Ingestion role
Masking policy for player contract information
🔍 Data Quality

The project validates:

Duplicate teams
Duplicate players
Duplicate matches
Duplicate deliveries
Deliveries without matches
Deliveries without strikers
Deliveries without bowlers
📈 Streamlit Dashboard

The Streamlit dashboard provides:

KPI Metrics
Total matches
Total runs
Total wickets
Total sixes
Match Analytics
Runs by match
Wickets by match
Player Analytics
Top batters
Top bowlers
Player performance
Team Analytics
Matches
Wins
Completed matches
📚 Advanced Snowflake Features

The project also demonstrates:

Time Travel
Zero-copy cloning
Semi-structured JSON
VARIANT
FLATTEN
Query performance analysis
Data sharing concepts