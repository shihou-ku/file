#!/bin/bash 

 

target_dir="/home/aishock/Dev/open-webui/backend/data/uploads" 

# Delete all files in the directory older than 1 day 

find "$target_dir" -maxdepth 1 -name "*.*" -mtime 0 -exec rm {} \; 

if [ "$(find "$target_dir" -maxdepth 1 -name "*.*" | wc -l)" -eq 0 ]; then 

    echo "No files were found in \"$target_dir\"." 
else 

    echo "All files in \"$target_dir\" older than 1 day have been deleted." 

fi
