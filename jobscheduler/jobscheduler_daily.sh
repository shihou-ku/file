#!/bin/bash

target_dir="/home/aishock/Dev/open-webui/src/jobscheduler/Daily"

if [[ -d "$target_dir" ]]; then
    for script in "$target_dir"/*.sh; do
        if [[ -f "$script" ]]; then
            echo "Running $script..."
            bash "$script"
        fi
    done
else
    echo "Directory $target_dir does not exist!"
fi
