#!/usr/bin/env bash

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Build context window progress bar (20 chars wide)
cwd=$(pwd | sed "s|$HOME|~|")

if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  filled=$(( used_int * 20 / 100 ))
  empty=$(( 20 - filled ))
  bar=""
  for i in $(seq 1 $filled); do bar="${bar}█"; done
  for i in $(seq 1 $empty); do bar="${bar}░"; done
  ctx_part=$(printf "%s \033[0;33m%d%%\033[0m" "$bar" "$used_int")
else
  ctx_part=""
fi

# Build rate limit section
rate_part=""
if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  # Color: green < 50%, yellow 50-79%, red >= 80%
  if [ "$five_int" -ge 80 ]; then
    rate_part=$(printf "\033[38;5;124m5h:%d%%\033[0m" "$five_int")
  elif [ "$five_int" -ge 50 ]; then
    rate_part=$(printf "\033[38;5;166m5h:%d%%\033[0m" "$five_int")
  else
    rate_part=$(printf "\033[38;5;136m5h:%d%%\033[0m" "$five_int")
  fi
fi
if [ -n "$week_pct" ]; then
  week_int=$(printf "%.0f" "$week_pct")
  if [ "$week_int" -ge 80 ]; then
    week_str=$(printf "\033[38;5;124m7d:%d%%\033[0m" "$week_int")
  elif [ "$week_int" -ge 50 ]; then
    week_str=$(printf "\033[38;5;166m7d:%d%%\033[0m" "$week_int")
  else
    week_str=$(printf "\033[38;5;136m7d:%d%%\033[0m" "$week_int")
  fi
  [ -n "$rate_part" ] && rate_part="$rate_part $week_str" || rate_part="$week_str"
fi

# Assemble output
output=$(printf "\033[0;36m%s\033[0m" "$model")
[ -n "$ctx_part" ] && output="$output  $ctx_part"
[ -n "$rate_part" ] && output="$output  $rate_part"
output="$output  \033[38;5;64m$cwd\033[0m"

printf "%b" "$output"
