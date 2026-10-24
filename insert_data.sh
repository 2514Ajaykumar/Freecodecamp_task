#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

GAME_VALUES=$(
  tail -n +2 games.csv |
    while IFS=, read -r year round winner opponent winner_goals opponent_goals
    do
      printf "(%s, '%s', '%s', '%s', %s, %s),\n" \
        "$year" "$round" "$winner" "$opponent" "$winner_goals" "$opponent_goals"
    done |
    sed '$ s/,$//'
)

$PSQL "
WITH game_data(year, round, winner, opponent, winner_goals, opponent_goals) AS (
  VALUES $GAME_VALUES
)
INSERT INTO teams(name)
SELECT team
FROM (
  SELECT winner AS team FROM game_data
  UNION
  SELECT opponent FROM game_data
) AS all_teams
ON CONFLICT (name) DO NOTHING;

WITH game_data(year, round, winner, opponent, winner_goals, opponent_goals) AS (
  VALUES $GAME_VALUES
)
INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT game_data.year, game_data.round, winner.team_id, opponent.team_id,
       game_data.winner_goals, game_data.opponent_goals
FROM game_data
JOIN teams AS winner ON winner.name = game_data.winner
JOIN teams AS opponent ON opponent.name = game_data.opponent;
"
