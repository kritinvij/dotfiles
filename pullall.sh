#!/bin/bash

BASE_DIR=$(pwd);
printf "Pulling in latest changes for all repositories...\n\n";

# Find all git repositories and update it to the main latest revision
for i in $(find . -name ".git" -maxdepth 2 | cut -c 3-); do
    # We have to go to the .git parent directory to call the pull command
    cd "$i";
    cd ..;

    CUR_FILE_FULLPATH=$(pwd)
    CUR_FILENAME="$(basename -- "$CUR_FILE_FULLPATH")"
    CUR_BRANCH=$(git branch --show-current)

    printf "=================== %s @ %s ===================\n" $CUR_FILENAME $CUR_BRANCH;

    # Switch to main branch
    # git checkout main;

    # Pull
    git pull;
    git fetch;
    git branch | grep -v "main" | grep -v "$(git rev-parse --abbrev-ref HEAD)" | xargs git branch -D;
    printf "\n";

    # Go back to the base parent directory
    cd $BASE_DIR;
done

printf "Completed fetching latest changes!";
