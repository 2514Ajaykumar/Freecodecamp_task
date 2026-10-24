#!/bin/bash
set -euo pipefail

psql --username=freecodecamp --dbname=periodic_table -X -v ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF (SELECT count(*) FROM elements) <> 10 THEN
    RAISE EXCEPTION 'expected 10 elements';
  END IF;
  IF EXISTS (SELECT 1 FROM elements WHERE atomic_number = 1000) THEN
    RAISE EXCEPTION 'atomic number 1000 should not exist';
  END IF;
  IF EXISTS (SELECT 1 FROM elements WHERE symbol !~ '^[A-Z]') THEN
    RAISE EXCEPTION 'an element symbol is not capitalized';
  END IF;
  IF (SELECT array_agg(type ORDER BY type) FROM types)
      <> ARRAY['metal', 'metalloid', 'nonmetal']::VARCHAR[] THEN
    RAISE EXCEPTION 'unexpected element types';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM (VALUES
      (1, 1.008::NUMERIC),
      (2, 4.0026),
      (3, 6.94),
      (4, 9.0122),
      (5, 10.81),
      (6, 12.011),
      (7, 14.007),
      (8, 15.999),
      (9, 18.998),
      (10, 20.18)
    ) AS expected(atomic_number, atomic_mass)
    LEFT JOIN properties USING (atomic_number)
    WHERE properties.atomic_mass IS DISTINCT FROM expected.atomic_mass
  ) THEN
    RAISE EXCEPTION 'atomic masses do not match the reference values';
  END IF;
  IF EXISTS (
    SELECT 1 FROM properties p
    LEFT JOIN elements e USING (atomic_number)
    LEFT JOIN types t USING (type_id)
    WHERE e.atomic_number IS NULL OR t.type_id IS NULL
       OR p.melting_point_celsius IS NULL
       OR p.boiling_point_celsius IS NULL
       OR p.type_id IS NULL
  ) THEN
    RAISE EXCEPTION 'properties contains an invalid reference or null value';
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'properties' AND column_name = 'type'
  ) THEN
    RAISE EXCEPTION 'properties should not have a type column';
  END IF;
END $$;
SQL

printf 'All database checks passed.\n'