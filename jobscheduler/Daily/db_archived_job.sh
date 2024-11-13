#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")
root_dir=$(realpath "$script_dir/../../..")
archived_script="$root_dir/src/eth/db_archived.sh"  
hist_update_script="$root_dir/src/eth/db_historical_update.sh"  
PYTHON_SCRIPT="$root_dir/src/eth/az_upload_chat.py"

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
	f.type,f.data
FROM chat c 
INNER JOIN user u ON c.user_id = u.id
left join feedback f on c.user_id = f.user_id and c.id=json_extract(f.chat_id, '$.message_id');
EOF

# Part 2: Upload to Azure 
python3 "$PYTHON_SCRIPT"

rm "$OUTPUT_FILE"


# Part 3: Archived database 
if [[ ! -f "$archived_script" ]]; then
    echo "Error: Archived DB script '$archived_script' not found!"
    exit 1
fi

if [[ ! -f "$hist_update_script" ]]; then
    echo "Error: Historical update script '$hist_update_script' not found!"
    exit 1
fi

# Step 4: Run db_archived.sh script
echo "Running archived DB script: $archived_script"
bash "$archived_script"

# Step 5: Run hist_update_script.sh script 
#if [[ $? -eq 0 ]]; then
#    echo "Archived DB script completed successfully."
#    
#    echo "Running historical update script: $hist_update_script"
#    bash "$hist_update_script"
#    
#    if [[ $? -eq 0 ]]; then
#        echo "Historical update script completed successfully."
#    else
#        echo "Error: Historical update script failed!"
#        exit 1
#    fi
#else
#    echo "Error: Archived DB script failed!"
#    exit 1
#fi
