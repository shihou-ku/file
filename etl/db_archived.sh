#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")
root_dir=$(realpath "$script_dir/../../..")

# For webui database
DATE=$(date +"%Y%m%d")
DATABASE="$root_dir/backend/data/webui.db"        
DESTINATION_DB="$root_dir/backend/archived/webui_$DATE.db"   
TABLES=("chat" "feedback" "file") 
 

# For vector storage
CHROMA_DB="$root_dir/backend/data/vector storage/chroma.db"  
CHROMA_BACKUP="$root_dir/backend/archived/chroma_$DATE.db"
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

# Step 1: delete from webui db
if sqlite3 "$DATABASE" ".backup '$DESTINATION_DB'"; then
    echo "Backup created successfully: $DESTINATION_DB"     

    for TABLE in "${TABLES[@]}"; do
        echo "Deleting all rows from $TABLE..."
        sqlite3 "$DATABASE" "DELETE FROM $TABLE;"
    done

    echo "All specified tables have been truncated."
else
    echo "Backup failed. No tables were modified."
fi

# Step 2: delete from vector db
if sqlite3 "$CHROMA_DB" ".backup '$CHROMA_BACKUP'"; then
    echo "Backup of Chroma created successfully: $CHROMA_BACKUP"

    for VECTOR_DB in "${VECTOR_DB_TABLES[@]}"; do
        echo "Deleting all rows from $VECTOR_DB in Chroma database..."
        sqlite3 "$CHROMA_DB" "DELETE FROM $VECTOR_DB;" 
    done

    echo "All specified tables in Chroma database have been truncated."

else
    echo "Failed to create backup of Chroma database. Deletion process will not proceed."
    exit 1
fi

# Step 3: Move folder from vector storage to the archive path
VECTOR_STORAGE_DIR="$root_dir/backend/data/vector storage/"
ARCHIVED_DIR="$root_dir/backend/archived/vector_storage/"

mkdir -p "$ARCHIVED_DIR"

# Find and move folder to the archive path
for dir in "$VECTOR_STORAGE_DIR"*/; do
    if [[ -d "$dir" ]]; then
        dir_name=$(basename "$dir")
        
        echo "Moving directory $dir_name to archive..."
        mv "$dir" "$ARCHIVED_DIR/"
        
        if [[ $? -eq 0 ]]; then
            echo "Successfully moved $dir_name to $ARCHIVED_DIR"
        else
            echo "Failed to move $dir_name."
            exit 1
        fi
    fi
done