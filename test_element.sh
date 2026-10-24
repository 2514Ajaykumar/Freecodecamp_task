#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
expected_hydrogen="The element with atomic number 1 is Hydrogen (H). It's a nonmetal, with a mass of 1.008 amu. Hydrogen has a melting point of -259.1 celsius and a boiling point of -252.9 celsius."

[[ "$("$script_dir/element.sh" 1)" == "$expected_hydrogen" ]]
[[ "$("$script_dir/element.sh" H)" == "$expected_hydrogen" ]]
[[ "$("$script_dir/element.sh" Hydrogen)" == "$expected_hydrogen" ]]
[[ "$("$script_dir/element.sh" h)" == "$expected_hydrogen" ]]
[[ "$("$script_dir/element.sh" hYDROGEN)" == "$expected_hydrogen" ]]
[[ "$("$script_dir/element.sh")" == "Please provide an element as an argument." ]]
[[ "$("$script_dir/element.sh" 1000)" == "I could not find that element in the database." ]]
[[ "$("$script_dir/element.sh" 9)" == "The element with atomic number 9 is Fluorine (F). It's a nonmetal, with a mass of 18.998 amu. Fluorine has a melting point of -220 celsius and a boiling point of -188.1 celsius." ]]
[[ "$("$script_dir/element.sh" 10)" == "The element with atomic number 10 is Neon (Ne). It's a nonmetal, with a mass of 20.18 amu. Neon has a melting point of -248.6 celsius and a boiling point of -246.1 celsius." ]]

psql --username=freecodecamp --dbname=periodic_table -X -v ON_ERROR_STOP=1 -At <<'SQL'
DO $$
BEGIN
  IF (SELECT count(*) FROM elements) <> 10 THEN
    RAISE EXCEPTION 'expected 10 elements';
  END IF;
  IF EXISTS (
    SELECT 1 FROM properties
    WHERE melting_point_celsius IS NULL
       OR boiling_point_celsius IS NULL
       OR type_id IS NULL
  ) THEN
    RAISE EXCEPTION 'properties contains a null required value';
  END IF;
  IF EXISTS (
    SELECT 1 FROM properties p
    LEFT JOIN types t USING (type_id)
    WHERE t.type_id IS NULL
  ) THEN
    RAISE EXCEPTION 'properties contains an invalid type_id';
  END IF;
END $$;
SQL

printf 'All element and database checks passed.\n'