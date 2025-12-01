#!/bin/bash

#
# Usage:
#   ./pull-all
#       Default "compact mode".
#       - Shows only UPDATED and FAILED repositories.
#       - UNCHANGED repos are hidden to reduce noise.
#       - Any repo not on "main" is ALWAYS shown in a separate
#         "Repositories that are not on `main` branch" section
#         before the summary table (with dirty/clean info).
#
#   ./pull-all --full
#       Full verbose mode.
#       - Shows ALL repositories, including UNCHANGED ones.
#       - Displays full git output for every repo inside a panel.
#
#   Change MAX_PROCS to change how many repos to fetch data
#   for in parallel.
#

# ========= Config =========
PRIMARY_BRANCH="main"
MIN_PANEL_WIDTH=120
MAX_PROCS=13

# ========= Colors =========
RED="\033[0;31m"
GREEN="\033[0;32m"        # normal green (not bright)
YELLOW="\033[0;33m"       # non-bold yellow
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

colorize() {
    printf "%b%s%b" "$1" "$2" "$RESET"
}

panel_width() {
    local cols
    cols=$(tput cols 2>/dev/null || echo "$MIN_PANEL_WIDTH")
    [ "$cols" -lt "$MIN_PANEL_WIDTH" ] && cols="$MIN_PANEL_WIDTH"
    echo "$cols"
}

print_panel() {
    local color="$1"
    local title="$2"
    local box_width="$3"
    local body_width=$((box_width - 4))  # inner width

    local max_title_len=$((box_width - 4))
    local padded_title="$title"

    if [ ${#padded_title} -gt "$max_title_len" ]; then
        padded_title="${padded_title:0:$((max_title_len - 1))}…"
    fi
    while [ ${#padded_title} -lt "$max_title_len" ]; do
        padded_title+=" "
    done

    local top="┌"
    local mid="├"
    local bot="└"
    local i
    for ((i = 0; i < box_width - 2; i++)); do
        top+="─"
        mid+="─"
        bot+="─"
    done
    top+="┐"
    mid+="┤"
    bot+="┘"

    local title_line="│ $padded_title │"

    printf "%b\n" "$(colorize "$color" "$top")"
    printf "%b\n" "$(colorize "$color" "$title_line")"
    printf "%b\n" "$(colorize "$color" "$mid")"

    # Body from stdin, wrapped
    while IFS='' read -r line || [[ -n "$line" ]]; do
        local text="$line"
        [ -z "$text" ] && text=""

        while :; do
            if [ ${#text} -le "$body_width" ]; then
                local clean="$text"
                while [ ${#clean} -lt "$body_width" ]; do clean+=" "; done
                printf "%b\n" "$(colorize "$color" "│") $clean $(colorize "$color" "│")"
                break
            else
                local chunk="${text:0:$body_width}"
                text="${text:$body_width}"
                local clean="$chunk"
                printf "%b\n" "$(colorize "$color" "│") $clean $(colorize "$color" "│")"
            fi
        done
    done

    printf "%b\n\n" "$(colorize "$color" "$bot")"
}

determine_status() {
    local branch="$1"
    local raw_output="$2"

    if [ "$branch" != "$PRIMARY_BRANCH" ]; then
        echo "SKIPPED"
    elif echo "$raw_output" | grep -E -qi '^(fatal:|error:)' ; then
        echo "FAILED"
    elif echo "$raw_output" | grep -q "Already up to date."; then
        echo "UNCHANGED"
    else
        echo "UPDATED"
    fi
}

# ---- Mode handling ----
FULL_MODE=0
if [ "$1" == "--full" ]; then
    FULL_MODE=1
fi

BASE_DIR=$(pwd)

printf "%b\n\n" "$(colorize "$BOLD$BLUE" "Pulling latest changes for all repositories...")"

REPOS=$(find . -maxdepth 2 -name ".git" | sed 's|^\./||')

# Explicit error when no repos found
if [ -z "$REPOS" ]; then
    printf "%b\n" "$(colorize "$RED" "No git repositories found (no .git dirs within maxdepth 2).")"
    exit 1
fi

SUMMARY_FILE=$(mktemp)
OFFMAIN_FILE=$(mktemp)
trap "rm -f \"$SUMMARY_FILE\" \"$OFFMAIN_FILE\"" EXIT

BOX_WIDTH=$(panel_width)
BODY_WIDTH=$((BOX_WIDTH - 4))

count=0

for i in $REPOS; do
(
    cd "$BASE_DIR/$i/.." || exit 1

    CUR_FILE_FULLPATH=$(pwd)
    CUR_FILENAME="$(basename -- "$CUR_FILE_FULLPATH")"
    CUR_BRANCH=$(git branch --show-current)

    # Detect dirty working tree
    if [ -n "$(git status --porcelain)" ]; then
        DIRTY_STATE="DIRTY"
    else
        DIRTY_STATE="CLEAN"
    fi

    # Track non-main branches (with cleanliness) for compact mode
    if [ "$CUR_BRANCH" != "$PRIMARY_BRANCH" ]; then
        printf "%s\t%s\t%s\n" "$CUR_FILENAME" "$CUR_BRANCH" "$DIRTY_STATE" >> "$OFFMAIN_FILE"
    fi

    # Run git operations
    # - Skip git pull for non-main branches
    # - Always fetch/prune and cleanup branches
    RAW_OUTPUT=$(
        if [ "$CUR_BRANCH" = "$PRIMARY_BRANCH" ]; then
            git pull 2>&1
        else
            echo -e "${YELLOW}Skipping pull because branch is not '$PRIMARY_BRANCH'${RESET}"
        fi
        git fetch --all --prune 2>&1
        git branch | grep -v "$PRIMARY_BRANCH" \
                   | grep -v "$(git rev-parse --abbrev-ref HEAD)" \
                   | xargs -r git branch -D 2>/dev/null
    )

    STATUS_LABEL=$(determine_status "$CUR_BRANCH" "$RAW_OUTPUT")

    # Record status for summary
    printf "%s\t%s\n" "$CUR_FILENAME" "$STATUS_LABEL" >> "$SUMMARY_FILE"

    # Colorize *keywords only*, leave rest white/default
    OUTPUT=$(echo "$RAW_OUTPUT" | sed \
        -e "s/Already up to date./$(echo -e "${RESET}Already up to date.${RESET}")/" \
        -e "s/^error:/$(echo -e "${RED}error:${RESET}")/" \
        -e "s/^fatal:/$(echo -e "${RED}fatal:${RESET}")/" \
        -e "s/\bdeleting\b/$(echo -e "${YELLOW}deleting${RESET}")/")

    # Header color
    HEADER_COLOR="$RESET"
    case "$STATUS_LABEL" in
        UPDATED)   HEADER_COLOR="$GREEN" ;;
        FAILED)    HEADER_COLOR="$RED" ;;
        UNCHANGED) HEADER_COLOR="$RESET" ;;  # unchanged box in default color
        SKIPPED)   HEADER_COLOR="$YELLOW" ;;
    esac

    # Decide whether to render this repo's box:
    # - Full mode: always show
    # - Compact mode: hide UNCHANGED, show others
    if [ "$FULL_MODE" -eq 1 ] || [ "$STATUS_LABEL" != "UNCHANGED" ]; then
        TITLE="$CUR_FILENAME @ $CUR_BRANCH [$STATUS_LABEL]"
        print_panel "$HEADER_COLOR" "$TITLE" "$BOX_WIDTH" <<< "$OUTPUT"
    fi

) &

    count=$((count + 1))
    if [ "$count" -ge "$MAX_PROCS" ]; then
        wait
        count=0
    fi
done

wait

# -------- Non-main branches (compact mode only) --------
if [ "$FULL_MODE" -eq 0 ] && [ -s "$OFFMAIN_FILE" ]; then
    printf "%b\n" "$(colorize "$BOLD" "Repositories that are not on \`$PRIMARY_BRANCH\` branch:")"
    while IFS=$'\t' read -r repo branch dirty; do
        if [ "$dirty" = "DIRTY" ]; then
            printf "  - %s @ %s (has uncommitted changes)\n" "$repo" "$branch"
        else
            printf "  - %s @ %s\n" "$repo" "$branch"
        fi
    done < "$OFFMAIN_FILE"
    printf "\n"
fi

# -------- Summary Table --------
UPDATED=0
UNCHANGED=0
FAILED=0

while IFS=$'\t' read -r repo status; do
    case "$status" in
        UPDATED)   UPDATED=$((UPDATED+1)) ;;
        UNCHANGED) UNCHANGED=$((UNCHANGED+1)) ;;
        FAILED)    FAILED=$((FAILED+1)) ;;
    esac
done < "$SUMMARY_FILE"

TOTAL=$((UPDATED + UNCHANGED + FAILED))

COL1=14
COL2=7
TW=$((COL1 + COL2 + 7))

TOP="┏"; for((i=0;i<TW-2;i++));do TOP+="━";done; TOP+="┓"
MID="┣"; for((i=0;i<COL1+2;i++));do MID+="━";done; MID+="╋"; for((i=0;i<COL2+2;i++));do MID+="━";done; MID+="┫"
BOT="┗"; for((i=0;i<COL1+2;i++));do BOT+="━";done; BOT+="┻"; for((i=0;i<COL2+2;i++));do BOT+="━";done; BOT+="┛"

printf "%b\n" "$(colorize "$BOLD" "Summary:")"
printf "%b\n" "$(colorize "$BLUE" "$TOP")"
printf "┃ %-*s ┃ %*s ┃\n" "$COL1" "Status" "$COL2" "Count"
printf "%b\n" "$(colorize "$BLUE" "$MID")"
printf "┃ %-*s ┃ %*d ┃\n" "$COL1" "Updated"   "$COL2" "$UPDATED"
printf "┃ %-*s ┃ %*d ┃\n" "$COL1" "Unchanged" "$COL2" "$UNCHANGED"
printf "┃ %-*s ┃ %*d ┃\n" "$COL1" "Failed"    "$COL2" "$FAILED"
printf "%b\n" "$(colorize "$BLUE" "$MID")"
printf "┃ %-*s ┃ %*d ┃\n" "$COL1" "Total"     "$COL2" "$TOTAL"
printf "%b\n\n" "$(colorize "$BLUE" "$BOT")"

printf "%b\n\n" "$(colorize "$BOLD$GREEN" "Completed fetching latest changes!")"
