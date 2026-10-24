#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c"

secret_number=$((RANDOM % 1000 + 1))

echo "Enter your username:"
read -r username
escaped_username=${username//\'/\'\'}

user_stats=$($PSQL "SELECT users.user_id || '|' || COUNT(games.game_id) || '|' || COALESCE(MIN(games.number_of_guesses)::text, '0') FROM users LEFT JOIN games USING(user_id) WHERE username = '$escaped_username' GROUP BY users.user_id;")

if [[ -n $user_stats ]]; then
  IFS='|' read -r user_id games_played best_game <<< "$user_stats"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
else
  user_id=$($PSQL "INSERT INTO users(username) VALUES('$escaped_username') RETURNING user_id;")
  echo "Welcome, $username! It looks like this is your first time here."
fi

echo "Guess the secret number between 1 and 1000:"
number_of_guesses=0
while true; do
  read -r guess
  number_of_guesses=$((number_of_guesses + 1))

  if [[ ! $guess =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ $guess == -* ]]; then
    guess_number=$((-10#${guess#-}))
  else
    guess_digits=${guess#+}
    guess_number=$((10#$guess_digits))
  fi

  if ((guess_number < secret_number)); then
    echo "It's higher than that, guess again:"
  elif ((guess_number > secret_number)); then
    echo "It's lower than that, guess again:"
  else
    break
  fi
done

echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
$PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($user_id, $number_of_guesses);" > /dev/null