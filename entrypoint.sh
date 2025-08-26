#!/bin/bash
set -e 

# Modify PYTHONPATH to include the src directory 
export PYTHONPATH="$PYTHONPATH:/app/src"

# Execute the command
exec "$@"