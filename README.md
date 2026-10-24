# Periodic Table

The `element.sh` program looks up an element by atomic number, symbol, or name. It connects to the `periodic_table` PostgreSQL database as the `freecodecamp` user.

```bash
./element.sh 1
./element.sh H
./element.sh Hydrogen
```

Run the acceptance checks with:

```bash
./test_element.sh
./test_database.sh
```

The database backup is `periodic_table.sql`. Restore it in the FreeCodeCamp environment with:

```bash
psql -U postgres < periodic_table.sql
```