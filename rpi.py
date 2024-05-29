import polars as pl

df = pl.read_csv("GameResults.csv")
teams = df["winner"].append(df["loser"]).unique()

def calc_wp(game_data, team):
  gp = pl.DataFrame.filter(game_data, (pl.col("winner") == team) | (pl.col("loser") == team))
  return pl.Series.sum(gp["winner"] == team) / pl.Series.count(gp["winner"])

def calc_wp2(game_data, team, team_drop):
  gp = pl.DataFrame.filter(
    game_data,
    ((pl.col("winner") == team) | (pl.col("loser") == team)) &
    ((pl.col("winner") != team_drop) | (pl.col("loser") == team_drop))
    )
  return pl.Series.sum(gp["winner"] == team) / pl.Series.count(gp["winner"])

def calc_wl(game_data, team, type):
  return pl.Series.sum(game_data[type] == team)

def calc_pd(game_data, team):
  gp = pl.DataFrame.filter(game_data, (pl.col("winner") == team) | (pl.col("loser") == team))
  pd = pl.DataFrame.with_columns(gp, 
                                 pl.when(pl.col("winner") == team)
                                 .then(pl.col("winner_score") - pl.col("loser_score"))
                                 .otherwise(pl.col("loser_score") - pl.col("winner_score"))
                                 .alias("pd"))
  return pl.Series.sum(pd["pd"])

def calc_owp(game_data, team):
  opp_games = pl.DataFrame.filter(game_data, (pl.col("winner") == team) | (pl.col("loser") == team))

 