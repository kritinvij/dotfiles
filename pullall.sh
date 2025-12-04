#!/bin/bash

#
# Usage:
#   ./pull-all
#       Default "compact mode".
#       - Shows only UPDATED and FAILED repositories.
#       - UNCHANGED repos are hidden to reduce noise.
#       - Any repo not on its primary branch is ALWAYS shown in a separate
#         "Repositories that are not on their primary branch" section
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
# Fallback primary branch name if we can't detect origin/HEAD
FALLBACK_PRIMARY_BRANCH="main"
MIN_PANEL_WIDTH=120
MAX_PROCS=13
GIT_TIMEOUT=60   # seconds for git operations (pull/fetch/etc.)

# Don't ever prompt for credentials / input; fail fast instead.
export GIT_TERMINAL_PROMPT=0

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

# Run a command with a timeout if `timeout` is available.
# Usage: with_timeout 60 git pull
with_timeout() {
    local seconds="$1"; shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
    else
        # Fallback: no timeout binary; just run the command normally.
        "$@"
    fi
}

# Detect the primary/default branch for the current repo.
# Preference order:
#   1) origin/HEAD symbolic-ref
#   2) `git remote show origin` HEAD branch
#   3) FALLBACK_PRIMARY_BRANCH
detect_primary_branch() {
    local primary

    # Example output: refs/remotes/origin/main
    primary=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

    if [ -z "$primary" ]; then
        primary=$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')
    fi

    if [ -z "$primary" ]; then
        primary="$FALLBACK_PRIMARY_BRANCH"
    fi

    echo "$primary"
}

determine_status() {
    local current_branch="$1"
    local primary_branch="$2"
    local raw_output="$3"
    local exit_code="$4"

    if [ "$current_branch" != "$primary_branch" ]; then
        echo "SKIPPED"
    # Any non-zero exit (including timeout=124) is a failure.
    elif [ -n "$exit_code" ] && [ "$exit_code" -ne 0 ]; then
        echo "FAILED"
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
OFFPRIMARY_FILE=$(mktemp)
trap "rm -f \"$SUMMARY_FILE\" \"$OFFPRIMARY_FILE\"" EXIT

BOX_WIDTH=$(panel_width)
BODY_WIDTH=$((BOX_WIDTH - 4))

count=0

for i in $REPOS; do
(
    cd "$BASE_DIR/$i/.." || exit 1

    CUR_FILE_FULLPATH=$(pwd)
    CUR_FILENAME="$(basename -- "$CUR_FILE_FULLPATH")"
    CUR_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

    # Determine this repo's primary branch
    PRIMARY_BRANCH="$(detect_primary_branch)"

    # Detect dirty working tree
    if [ -n "$(git status --porcelain)" ]; then
        DIRTY_STATE="DIRTY"
    else
        DIRTY_STATE="CLEAN"
    fi

    # Track non-primary branches (with cleanliness) for compact mode
    if [ -n "$CUR_BRANCH" ] && [ "$CUR_BRANCH" != "$PRIMARY_BRANCH" ]; then
        # repo, current-branch, primary-branch, dirty/clean
        printf "%s\t%s\t%s\t%s\n" "$CUR_FILENAME" "$CUR_BRANCH" "$PRIMARY_BRANCH" "$DIRTY_STATE" >> "$OFFPRIMARY_FILE"
    fi

    # Run git operations
    # - Skip git pull for non-primary branches
    # - Always fetch/prune and cleanup branches
    TMP_OUT=$(mktemp)
    STATUS_EXIT=0

    {
        if [ -n "$CUR_BRANCH" ] && [ "$CUR_BRANCH" = "$PRIMARY_BRANCH" ]; then
            with_timeout "$GIT_TIMEOUT" git pull || STATUS_EXIT=$?
        else
            echo -e "${YELLOW}Skipping pull because branch is not '$PRIMARY_BRANCH'${RESET}"
        fi

        # Even if pull fails or is skipped, still try fetch/prune with timeout.
        with_timeout "$GIT_TIMEOUT" git fetch --all --prune || STATUS_EXIT=$?

        git branch | grep -v "$PRIMARY_BRANCH" \
                   | grep -v "$(git rev-parse --abbrev-ref HEAD)" \
                   | xargs -r git branch -D 2>/dev/null || true
    } &> "$TMP_OUT"

    RAW_OUTPUT=$(cat "$TMP_OUT")
    rm -f "$TMP_OUT"

    # If the timeout command killed the operation (usual exit code 124), annotate the output.
    if [ "$STATUS_EXIT" -eq 124 ]; then
        RAW_OUTPUT="${RAW_OUTPUT}\n[Timed out after ${GIT_TIMEOUT}s]"
    fi

    STATUS_LABEL=$(determine_status "$CUR_BRANCH" "$PRIMARY_BRANCH" "$RAW_OUTPUT" "$STATUS_EXIT")

    # Record status for summary
    printf "%s\t%s\n" "$CUR_FILENAME" "$STATUS_LABEL" >> "$SUMMARY_FILE"

    # Colorize *keywords only*, leave rest white/default
    OUTPUT=$(echo -e "$RAW_OUTPUT" | sed \
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
        TITLE="$CUR_FILENAME @ ${CUR_BRANCH:-"(no branch)"} [$STATUS_LABEL] (primary: $PRIMARY_BRANCH)"
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

# -------- Non-primary branches (compact mode only) --------
if [ "$FULL_MODE" -eq 0 ] && [ -s "$OFFPRIMARY_FILE" ]; then
    printf "%b\n" "$(colorize "$BOLD" "Repositories that are not on their primary branch:")"
    while IFS=$'\t' read -r repo branch primary dirty; do
        if [ "$dirty" = "DIRTY" ]; then
            printf "  - %s @ %s (primary: %s, has uncommitted changes)\n" "$repo" "$branch" "$primary"
        else
            printf "  - %s @ %s (primary: %s)\n" "$repo" "$branch" "$primary"
        fi
    done < "$OFFPRIMARY_FILE"
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
