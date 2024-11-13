#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")
root_dir=$(realpath "$script_dir/../../..")
TODAY_DATE=$(date +"%Y%m%d")

# For Webui
WEBUI_DB_ARCHIVE_FILES="$root_dir/backend/archived/webui_$TODAY_DATE.db"
WEBUI_HIST_DB="$root_dir/backend/data/webui_historical.db"

WEBUI_TABLES=(
    "chat"
    "feedback"
    "file"
)

# For vector storage
VECTOR_DB_ARCHIVE_FILES=("$root_dir/backend/archived/vector_storage/chroma_$TODAY_DATE.db") 
VECTOR_HIST_DB="$root_dir/backend/data/chroma_historical.db"

VECTOR_DB_TABLES=(
    "collection_metadata"
    "collections"
    "embedding_fulltext_search"
    "embedding_fulltext_search_content"
    "embedding_fulltext_search_data"
    "embedding_fulltext_search_docsize"
    "embedding_fulltext_search_idx"
    "embedding_metadata"
    "embeddings"
    "embeddings_queue"
    "max_seq_id"
    "segment_metadata"
    "segments"
)

# Step 1: Add `inserted_date` column if it doesn't exist
for table in "${VECTOR_DB_TABLES[@]}"; do
    column_check=$(sqlite3 "$VECTOR_HIST_DB" "PRAGMA table_info($table);" | grep -w 'inserted_date')

    if [[ -z "$column_check" ]]; then
        sqlite3 "$VECTOR_HIST_DB" "ALTER TABLE $table ADD COLUMN inserted_date TEXT;"
    fi
done

for webui_table in "${WEBUI_TABLES[@]}"; do
    column_check=$(sqlite3 "$WEBUI_DB_ARCHIVE_FILES" "PRAGMA table_info($webui_table);" | grep -w 'inserted_date')

    if [[ -z "$column_check" ]]; then
        sqlite3 "$WEBUI_DB_ARCHIVE_FILES" "ALTER TABLE $webui_table ADD COLUMN inserted_date TEXT;"
    fi
done

# Step 2: Insert Data from Today Archived DB into Historical Table
if [[ -f "$VECTOR_DB_ARCHIVE_FILES" ]]; then
    for table in "${VECTOR_DB_TABLES[@]}"; do
        # Exclude the primary key column
        case "$table" in
            "collection_metadata") columns="collection_id, key, str_value, int_value, float_value, bool_value";;
            "collections") columns="id, name, dimension, database_id, config_json_str";;
            "embedding_fulltext_search") columns="string_value";;
            "embedding_fulltext_search_content") columns="c0";;
            "embedding_fulltext_search_data") columns="block";;
            "embedding_fulltext_search_docsize") columns="sz";;
            "embedding_fulltext_search_idx") columns="segid, term, pgno";;
            "embedding_metadata") columns="id, key, string_value, int_value, float_value, bool_value";;
            "embeddings") columns="segment_id, embedding_id, seq_id, created_at";;
            "embeddings_queue") columns="seq_id, created_at, operation, topic, id, vector, encoding, metadata";;
            "max_seq_id") columns="segment_id, seq_id";;
            "segment_metadata") columns="segment_id, key, str_value, int_value, float_value, bool_value";;
            "segments") columns="id, other_column";;
            *) continue ;;
        esac
			
		# Perform data ingestion to historical table
        sqlite3 "$VECTOR_DB_ARCHIVE_FILES" "ATTACH DATABASE '$VECTOR_HIST_DB' AS hist; 
            DELETE FROM hist.$table WHERE inserted_date = '$TODAY_DATE';"
        
        sqlite3 "$VECTOR_DB_ARCHIVE_FILES" "ATTACH DATABASE '$VECTOR_HIST_DB' AS hist; 
            INSERT INTO hist.$table ($columns, inserted_date) 
            SELECT $columns, '$TODAY_DATE' FROM $table;"
    done
	rm -f "$VECTOR_DB_ARCHIVE_FILES"
else
    echo "Archived database for today ($TODAY_DATE) not found: $archived_db"
fi
done

# Webui table
if [[ -f "$WEBUI_DB_ARCHIVE_FILES" ]]; then
    for table in "${WEBUI_TABLES[@]}"; do
		# Exclude the primary key column
        case "$table" in
            "chat") columns="id, user_id, title, share_id, archived, ,created_at, updated_at, chat, pinned, meta, folder_id";;
            "feedback") columns="id, user_id, version, type, data, meta, snapshot, created_at, updated_at";;
            "file") columns="id, user_id, filename, meta, created_at, hash, data, updated_at, path";;
            *) echo "No columns defined for table $table"
                continue ;;
        esac
        
        # Perform data ingestion to historical table
        sqlite3 "$WEBUI_DB_ARCHIVE_FILES" "ATTACH DATABASE '$WEBUI_HIST_DB' AS webui_hist;
            DELETE FROM webui_hist.$table WHERE inserted_date = '$TODAY_DATE';"
        
        sqlite3 "$WEBUI_DB_ARCHIVE_FILES" "ATTACH DATABASE '$WEBUI_HIST_DB' AS webui_hist; 
            INSERT INTO webui_hist.$table ($columns, inserted_date) 
            SELECT $columns, '$TODAY_DATE' FROM $table;"
    done
	rm -f "$WEBUI_DB_ARCHIVE_FILES"
else
    echo "Archived WebUI database for today ($TODAY_DATE) not found: $WEBUI_DB_ARCHIVE_FILES"
fi

echo "Data insertion completed for $TODAY_DATE."
