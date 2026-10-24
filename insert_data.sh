#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

declare -A teams
team_values=""
game_values=""

while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  if [[ $year == "year" ]]
  then
    continue
  fi

  for team in "$winner" "$opponent"
  do
    if [[ -z ${teams[$team]} ]]
    then
      teams[$team]=1
      team_values+=" ,('$team')"
    fi
  done

  game_values+=" ,($year, '$round', '$winner', '$opponent', $winner_goals, $opponent_goals)"
done < games.csv

team_values=${team_values:2}
game_values=${game_values:2}

$PSQL "INSERT INTO teams (name) VALUES $team_values ON CONFLICT (name) DO NOTHING;
INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT game_data.year, game_data.round, winner_team.team_id, opponent_team.team_id,
       game_data.winner_goals, game_data.opponent_goals
FROM (VALUES $game_values) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals)
JOIN teams AS winner_team ON winner_team.name = game_data.winner
JOIN teams AS opponent_team ON opponent_team.name = game_data.opponent;"
