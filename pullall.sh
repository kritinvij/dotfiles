#!/bin/bash

# Store the current dir
CUR_DIR=$(pwd)

# Let the person running the script know what's going on.
echo "\nPulling in latest changes for all repositories...\n"

# Find all git repositories and update it to the main latest revision
for i in $(find . -name ".git" | cut -c 3-); do
    echo $i+;

    # We have to go to the .git parent directory to call the pull command
    cd "$i";
    cd ..;

    # Switch to main branch
    # git checkout main;

    # Pull
    echo $pwd;
    git pull;

    # Go back to the CUR_DIR
    cd $CUR_DIR;
done

echo "\nCompleted fetching latest code!\n"
