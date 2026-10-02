#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read USERNAME
SAFE_USERNAME=${USERNAME//\'/\'\'}

USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$SAFE_USERNAME'")

if [[ -z $USER_DATA ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  IFS='|' read GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "Guess the secret number between 1 and 1000:"
GUESSES=0

while true
do
  read GUESS

  if [[ ! $GUESS =~ ^-?[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  (( GUESSES++ ))

  if [[ $GUESS == -* ]]
  then
    echo "It's higher than that, guess again:"
    continue
  fi

  GUESS_NUMBER=$(( 10#$GUESS ))

  if (( GUESS_NUMBER == SECRET_NUMBER ))
  then
    break
  elif (( GUESS_NUMBER > SECRET_NUMBER ))
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

if [[ -z $USER_DATA ]]
then
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$SAFE_USERNAME', 1, $GUESSES)" > /dev/null
else
  $PSQL "UPDATE users SET games_played = games_played + 1, best_game = LEAST(best_game, $GUESSES) WHERE username = '$SAFE_USERNAME'" > /dev/null
fi

echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
