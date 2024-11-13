#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")
root_dir=$(realpath "$script_dir/../../..")

# From vector storage
TODAY_DATE=$(date +"%Y%m%d")
ARCHIVED_DIR="$root_dir/backend/archived/vector_storage/"
VECTOR_DB_ARCHIVE_FILES=("$ARCHIVED_DIR/chroma_$TODAY_DATE.db") 
HISTORICAL_DB="$root_dir/backend/data/historical.db"

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
    column_check=$(sqlite3 "$HISTORICAL_DB" "PRAGMA table_info($table);" | grep -w 'inserted_date')

    if [[ -z "$column_check" ]]; then
        sqlite3 "$HISTORICAL_DB" "ALTER TABLE $table ADD COLUMN inserted_date TEXT;"
    fi
done

# Step 2: Insert Data from Today Archived Vector DB into Historical Table
for archived_db in "${VECTOR_DB_ARCHIVE_FILES[@]}"; do
    if [[ -f "$archived_db" ]]; then

        # Iterate each table in the archived database
        for table in "${VECTOR_DB_TABLES[@]}"; do
            # Exclude the primary key column
            case "$table" in
                "collection_metadata")
                    columns="collection_id, key, str_value, int_value, float_value, bool_value";;
                "collections")
                    columns="id, name, dimension, database_id, config_json_str";;
                "embedding_fulltext_search")
                    columns="string_value";;
                "embedding_fulltext_search_content")
                    columns="c0";;
                "embedding_fulltext_search_data")
                    columns="block";;
                "embedding_fulltext_search_docsize")
                    columns="sz";;
                "embedding_fulltext_search_idx")
                    columns="segid, term, pgno";;
                "embedding_metadata")
                    columns="id, key, string_value, int_value, float_value, bool_value";;
                "embeddings")
                    columns="segment_id, embedding_id, seq_id, created_at";;
                "embeddings_queue")
                    columns="seq_id, created_at, operation, topic, id, vector, encoding, metadata";;
                "max_seq_id")
                    columns="segment_id, seq_id";;
                "segment_metadata")
                    columns="segment_id, key, str_value, int_value, float_value, bool_value";;
                "segments")
                    columns="id, other_column";;
                *)
                    echo "No columns defined for table $table"
                    continue
                    ;;
            esac
			
			# Perform data ingestion to historical table
			sqlite3 "$archived_db" "ATTACH DATABASE '$HISTORICAL_DB' AS hist; 
                DELETE FROM hist.$table WHERE inserted_date = '$TODAY_DATE';"

            if sqlite3 "$archived_db" "ATTACH DATABASE '$HISTORICAL_DB' AS hist; 
                INSERT INTO hist.$table ($columns, inserted_date) 
                SELECT $columns, '$TODAY_DATE' FROM $table;" ;  then
				exit 1
            fi
        done
    else
        echo "Archived database for today ($TODAY_DATE) not found: $archived_db"
    fi
done

echo "All data from archived vector databases for $TODAY_DATE have been inserted into historical tables."
