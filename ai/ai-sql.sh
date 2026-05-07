#!/usr/bin/env bash
# usage: ai-sql [--dialect postgres|mysql|sqlite] [--schema FILE] "question"
#
# Translate a natural-language question into a SQL query. Provide the schema
# via --schema FILE (a .sql or text file with CREATE TABLE statements) for
# accurate column/table names.
#
# Examples:
#   ai-sql --schema schema.sql "top 10 customers by revenue last month"
#   ai-sql --dialect mysql "users created today, with their order count"

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

dialect="postgres"
schema=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dialect) dialect="$2"; shift 2 ;;
    --schema)  schema="$2"; shift 2 ;;
    -h|--help) show_help_and_exit ;;
    *) break ;;
  esac
done

[[ $# -eq 0 ]] && show_help_and_exit
question="$*"

schema_block=""
if [[ -n "$schema" ]]; then
  [[ -f "$schema" ]] || die "Schema file not found: $schema"
  schema_block="Schema:
\`\`\`sql
$(cat "$schema")
\`\`\`
"
fi

prompt="You are a SQL expert. Write a $dialect query that answers this question:

\"$question\"

$schema_block
Output format:
\`\`\`sql
<query>
\`\`\`

Then 1-3 short bullet points explaining the query. If you had to guess at
table or column names, say so. Prefer JOINs over subqueries when both work.
Avoid SELECT *."

printf '%s' "$prompt" | ai_call
