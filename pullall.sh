#!/bin/bash

CUR_DIR=$(pwd)
echo "Pulling in latest changes for all repositories..."

# Find all git repositories and update it to the main latest revision
for i in $(find . -name ".git" | cut -c 3-); do
    echo $i;

    # We have to go to the .git parent directory to call the pull command
    cd "$i";
    cd ..;

    # Switch to main branch
    # git checkout main;

    # Pull
    git pull;

    # Go back to the base parent directory
    cd $CUR_DIR
done

echo "Completed fetching latest changes!"
