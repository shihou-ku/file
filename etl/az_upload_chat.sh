#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")
root_dir=$(realpath "$script_dir/../../..")

# Part 1: Extract data from SQLite database 
# Define database and output file 
DATE=$(date +"%Y%m%d") 
YEAR=$(date +"%Y") 
MONTH=$(date +"%m") 

DATABASE="$root_dir/backend/data/webui.db"        
OUTPUT_FILE="$script_dir/output_$DATE.txt"   

if [[ ! -f "$DATABASE" ]]; then 
    echo "Database file not found!" 
    exit 1 
fi 

# Execute the SQLite query and save the result to the output file
sqlite3 "$DATABASE" <<EOF > "$OUTPUT_FILE"
.headers on
.mode csv
SELECT  
    SUBSTR(u.email, INSTR(u.email, '@') + 1) AS EmailGroup,  
    c.*
	f.type,f.data, f.meta
FROM chat c 
INNER JOIN user u ON c.user_id = u.id
left join feedback f on c.user_id = f.user_id and c.id=json_extract(f.chat_id, '$.message_id');
EOF

# Part 2: Upload to Azure 
PYTHON_SCRIPT="$script_dir/az_upload_chat.py"
python3 "$PYTHON_SCRIPT"

rm "$OUTPUT_FILE"
