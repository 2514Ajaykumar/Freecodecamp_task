#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -X -q -t -A"

printf "\n~~~~~ MY SALON ~~~~~\n\n"
printf "Welcome to My Salon, how can I help you?\n\n"

while true; do
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
  read SERVICE_ID_SELECTED

  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]] && [[ -n "$($PSQL -c "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED;")" ]]; then
    break
  fi

  printf "\nI could not find that service. What would you like today?\n"
done

SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE

CUSTOMER_ID=$($PSQL -v phone="$CUSTOMER_PHONE" <<< "SELECT customer_id FROM customers WHERE phone = :'phone';")

if [[ -z "$CUSTOMER_ID" ]]; then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  read CUSTOMER_NAME
  $PSQL -v phone="$CUSTOMER_PHONE" -v name="$CUSTOMER_NAME" <<< "INSERT INTO customers (phone, name) VALUES (:'phone', :'name');"
  CUSTOMER_ID=$($PSQL -v phone="$CUSTOMER_PHONE" <<< "SELECT customer_id FROM customers WHERE phone = :'phone';")
else
  CUSTOMER_NAME=$($PSQL -v customer_id="$CUSTOMER_ID" <<< "SELECT name FROM customers WHERE customer_id = :customer_id;")
fi

printf "\nWhat time would you like your %s, %s?\n" "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME

$PSQL -v customer_id="$CUSTOMER_ID" -v service_id="$SERVICE_ID_SELECTED" -v service_time="$SERVICE_TIME" <<< "INSERT INTO appointments (customer_id, service_id, time) VALUES (:customer_id, :service_id, :'service_time');"

printf "\nI have put you down for a %s at %s, %s.\n" "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"