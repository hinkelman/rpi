import polars as pl
import statistics as stats

df = pl.read_csv("GameResults.csv")
teams = df["winner"].append(df["loser"]).unique()

def calc_wp(game_data, team, team_drop = None):
  gp = pl.DataFrame.filter(game_data, (pl.col("winner") == team) | (pl.col("loser") == team))
  if team_drop is not None:
    gp = pl.DataFrame.filter(gp, (pl.col("winner") != team_drop) & (pl.col("loser") != team_drop))
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
  opp = pl.DataFrame.with_columns(opp_games,
                                  pl.when(pl.col("winner") == team)
                                  .then(pl.col("loser"))
                                  .otherwise(pl.col("winner"))
                                  .alias("opp"))
  return stats.mean([calc_wp(game_data, x, team) for x in opp["opp"]])

def calc_oowp(game_data, team):
  opp_games = pl.DataFrame.filter(game_data, (pl.col("winner") == team) | (pl.col("loser") == team))
  opp = pl.DataFrame.with_columns(opp_games,
                                  pl.when(pl.col("winner") == team)
                                  .then(pl.col("loser"))
                                  .otherwise(pl.col("winner"))
                                  .alias("opp"))
  return stats.mean([calc_owp(game_data, x) for x in opp["opp"]])

def calc_sos(game_data, team):
  return (2 * calc_owp(game_data, team) + calc_oowp(game_data, team)) / 3

def calc_rpi(game_data, team):
  rpi = 0.25 * calc_wp(game_data, team) + \
    0.5 * calc_owp(game_data, team) + \
    0.25 * calc_oowp(game_data, team)
  return rpi

final = pl.DataFrame(
  {
    "team": teams,
    "win": [calc_wl(df, x, "winner") for x in teams],
    "loss": [calc_wl(df, x, "loser") for x in teams],
    "wp": [calc_wp(df, x) for x in teams],
    "pd": [calc_pd(df, x) for x in teams],
    "sos": [calc_sos(df, x) for x in teams],
    "rpi": [calc_rpi(df, x) for x in teams]
  }
)

pl.Config.set_tbl_rows(14)
pl.DataFrame.sort(final, "rpi", descending = True)
