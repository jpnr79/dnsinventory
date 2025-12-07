#!/usr/bin/env bash
set -euo pipefail

# migrate_to_glpi11.sh
# Checks `glpi_plugin_dnsinventory` tables and applies the provided migration (sql/1.2.0.sql)
# Usage: ./migrate_to_glpi11.sh -h

print_help(){
  cat <<'EOF'
Usage: migrate_to_glpi11.sh -u DB_USER -p DB_PASS -d DB_NAME [-h] [--run]

This script:
 - Creates a dump backup of the GLPI database (to current directory)
 - Checks if `glpi_plugin_dnsinventory_configs.id` is UNSIGNED
 - If not UNSIGNED, it applies the migration SQL file `sql/1.2.0.sql`
 - Shows the resulting `SHOW CREATE TABLE` for verification

Options:
 -u DB_USER    MySQL user
 -p DB_PASS    MySQL password (beware of shell history)
 -d DB_NAME    Database name (GLPI database)
 --run         Actually run the migration (without this flag will only report)
 -h            Show this help and exit

Examples:
  DB_USER=root DB_PASS=secret DB_NAME=glpi ./migrate_to_glpi11.sh --run
  ./migrate_to_glpi11.sh -u root -p secret -d glpi --run
EOF
}

# Parse args
RUN=false
DB_USER=""
DB_PASS=""
DB_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u) DB_USER="$2"; shift 2;;
    -p) DB_PASS="$2"; shift 2;;
    -d) DB_NAME="$2"; shift 2;;
    --run) RUN=true; shift;;
    -h|--help) print_help; exit 0;;
    *) echo "Unknown arg: $1"; print_help; exit 1;;
  esac
done

# Allow env vars fallback
DB_USER=${DB_USER:-${DB_USER_ENV:-}}
DB_PASS=${DB_PASS:-${DB_PASS_ENV:-}}
DB_NAME=${DB_NAME:-${DB_NAME_ENV:-}}

if [[ -z "$DB_USER" || -z "$DB_PASS" || -z "$DB_NAME" ]]; then
  echo "Missing DB credentials. Provide -u, -p and -d or set DB_USER, DB_PASS, DB_NAME env vars."
  exit 2
fi

SQL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/sql"
MIGRATION_SQL="$SQL_DIR/1.2.0.sql"

if [[ ! -f "$MIGRATION_SQL" ]]; then
  echo "Migration SQL not found at $MIGRATION_SQL"
  exit 3
fi

TIMESTAMP=$(date +%F_%H%M%S)
BACKUP_FILE="$PWD/glpi_backup_${TIMESTAMP}.sql"

echo "[1/5] Creating DB backup to $BACKUP_FILE"
mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE"

echo "[2/5] Checking current column attributes for glpi_plugin_dnsinventory_configs.id"
CHECK_SQL="SELECT COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY, EXTRA FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='glpi_plugin_dnsinventory_configs' AND COLUMN_NAME='id';"

CURRENT_INFO=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "$CHECK_SQL") || true

if [[ -z "$CURRENT_INFO" ]]; then
  echo "Table or column not found. The plugin tables may not exist yet."
  echo "If tables do not exist, installing the plugin from GLPI will create them with the updated SQL in sql/1.0.0.sql."
  exit 0
fi

echo "Current column info:"
echo "$CURRENT_INFO"

# Determine if COLUMN_TYPE contains 'unsigned'
if echo "$CURRENT_INFO" | tr '[:upper:]' '[:lower:]' | grep -q "unsigned"; then
  echo "\nNo action required: 'id' is already UNSIGNED."
  echo "Showing current CREATE TABLE for verification."
  mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "SHOW CREATE TABLE \\`glpi_plugin_dnsinventory_configs\\`\G"
  exit 0
fi

if [[ "$RUN" != true ]]; then
  echo "\nMigration needed: 'id' is NOT UNSIGNED."
  echo "Run the script with --run to apply migration. Example:"
  echo "  ./migrate_to_glpi11.sh -u root -p secret -d glpi --run"
  exit 0
fi

# Ask for confirmation
read -p "Proceed to apply migration SQL ($MIGRATION_SQL) to database $DB_NAME? (type 'yes' to continue): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Aborted by user. No changes made."
  exit 5
fi

echo "[3/5] Applying migration SQL: $MIGRATION_SQL"
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$MIGRATION_SQL"

echo "[4/5] Verifying the changes"
mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "SHOW CREATE TABLE \\`glpi_plugin_dnsinventory_configs\\`\G"
mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "SHOW CREATE TABLE \\`glpi_plugin_dnsinventory_servers\\`\G"

echo "[5/5] Migration completed. Keep the DB backup at $BACKUP_FILE if you need to restore."

exit 0
