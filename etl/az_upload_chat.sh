#!/bin/bash 

# Part 1: Extract data from SQLite database 
# Define database and output file 
DATE=$(date +"%Y%m%d") 
YEAR=$(date +"%Y") 
MONTH=$(date +"%m") 

DATABASE="/home/aishock/Dev/open-webui/backend/data/webui.db"        
OUTPUT_FILE="/home/aishock/Dev/open-webui/src/etl/output_$DATE.txt"   

if [[ ! -f "$DATABASE" ]]; then 
    echo "Database file not found!" 
    exit 1 
fi 

sqlite3 "$DATABASE" <<EOF > "$OUTPUT_FILE"
.headers on
.mode csv
SELECT  
    SUBSTR(u.email, INSTR(u.email, '@') + 1) AS EmailGroup,  
    c.*  
FROM chat c 
INNER JOIN user u ON c.user_id = u.id;
EOF

# Part 2: Upload to azure 
PYTHON_SCRIPT="/home/aishock/Dev/open-webui/src/etl/az_upload_chat.py"
python3 "$PYTHON_SCRIPT"

rm "$OUTPUT_FILE"
