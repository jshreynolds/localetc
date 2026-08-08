#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

get() {
  echo "$input" | jq -r "$1 // empty" 2>/dev/null || true
}

# format a token count compactly: 47210 -> 47.2k, empty -> empty
fmt_k() {
  local n="$1"
  [ -z "$n" ] && return
  awk -v n="$n" 'BEGIN {
    if (n < 1000) { printf "%d", n; exit }
    k = n / 1000
    if (k == int(k)) printf "%dk", k; else printf "%.1fk", k
  }'
}

# format seconds-until epoch as "2h14m" / "45m", empty -> empty
fmt_reset() {
  local epoch="$1"
  [ -z "$epoch" ] && return
  local now delta
  now="$(date +%s)"
  delta=$((epoch - now))
  [ "$delta" -le 0 ] && { printf 'now'; return; }
  local h=$((delta / 3600)) m=$(((delta % 3600) / 60))
  if [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

# ANSI colors (disable by exporting NO_COLOR)
if [ -z "${NO_COLOR:-}" ]; then
  c_reset=$'\033[0m'; c_dim=$'\033[90m'; c_bold=$'\033[1m'
  c_red=$'\033[31m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'
  c_blue=$'\033[34m'; c_magenta=$'\033[35m'; c_cyan=$'\033[36m'
else
  c_reset=; c_dim=; c_bold=; c_red=; c_green=; c_yellow=; c_blue=; c_magenta=; c_cyan=
fi

# pick a color by numeric thresholds: value warn crit -> green/yellow/red
# (crit==high means bigger is worse; used for context fill)
color_high() {
  local v="${1%%.*}" warn="$2" crit="$3"
  case "$v" in ''|*[!0-9]*) printf '%s' "$c_dim"; return;; esac
  if [ "$v" -ge "$crit" ]; then printf '%s' "$c_red"
  elif [ "$v" -ge "$warn" ]; then printf '%s' "$c_yellow"
  else printf '%s' "$c_green"; fi
}

# bigger is better (used for cache hit rate)
color_low() {
  local v="${1%%.*}" good="$2" ok="$3"
  case "$v" in ''|*[!0-9]*) printf '%s' "$c_dim"; return;; esac
  if [ "$v" -ge "$good" ]; then printf '%s' "$c_green"
  elif [ "$v" -ge "$ok" ]; then printf '%s' "$c_yellow"
  else printf '%s' "$c_red"; fi
}

model="$(get '.model.display_name')"
[ -z "$model" ] && model="$(get '.model.id')"
[ -z "$model" ] && model="unknown-model"

cwd="$(get '.workspace.current_dir')"
[ -z "$cwd" ] && cwd="$(get '.cwd')"
[ -n "$cwd" ] && cwd="$(basename "$cwd")"

branch="$(get '.workspace.git_branch')"
[ -z "$branch" ] && branch="$(get '.git.branch')"

ctx_pct="$(get '.context_window.used_percentage')"
ctx_size="$(get '.context_window.context_window_size')"
ctx_in="$(get '.context_window.total_input_tokens')"
ctx_out="$(get '.context_window.total_output_tokens')"

# per-turn breakdown; current_usage is null before first API call and after /compact
cache_fresh="$(get '.context_window.current_usage.input_tokens')"
cache_write="$(get '.context_window.current_usage.cache_creation_input_tokens')"
cache_read="$(get '.context_window.current_usage.cache_read_input_tokens')"

rl_5h_pct="$(get '.rate_limits.five_hour.used_percentage')"
rl_5h_reset="$(get '.rate_limits.five_hour.resets_at')"
rl_7d_pct="$(get '.rate_limits.seven_day.used_percentage')"
rl_7d_reset="$(get '.rate_limits.seven_day.resets_at')"

cost="$(get '.cost.total_cost_usd')"
[ -z "$cost" ] && cost="$(get '.cost_usd')"
[ -n "$cost" ] && cost="$(awk -v c="$cost" 'BEGIN { printf "%.2f", c }')"

thinking="$(get '.thinking.enabled')"

mode="$(get '.mode')"
[ -z "$mode" ] && mode="$(get '.output_style.name')"

parts=()

parts+=("${c_bold}${c_cyan}${model}${c_reset}")

[ -n "$cwd" ] && parts+=("${c_dim}dir:${c_reset}${c_blue}${cwd}${c_reset}")
[ -n "$branch" ] && parts+=("${c_dim}git:${c_reset}${c_magenta}${branch}${c_reset}")

ctx_in_h="$(fmt_k "$ctx_in")"
ctx_out_h="$(fmt_k "$ctx_out")"
ctx_size_h="$(fmt_k "$ctx_size")"

# fill-based threshold color, applied to the used-input value in the io section
# green < 50% < yellow < 80% < red
ctx_color="$(color_high "$ctx_pct" 50 80)"
if [ -n "$ctx_pct" ] && [ -n "$ctx_size_h" ]; then
  parts+=("${c_dim}ctx:${c_reset}${ctx_pct}% ${c_dim}(${ctx_size_h})${c_reset}")
elif [ -n "$ctx_pct" ]; then
  parts+=("${c_dim}ctx:${c_reset}${ctx_pct}%")
elif [ -n "$ctx_size_h" ]; then
  parts+=("${c_dim}ctx:(${ctx_size_h})${c_reset}")
fi

if [ -n "$ctx_in_h" ] || [ -n "$ctx_out_h" ]; then
  parts+=("${c_dim}io:${c_reset}${ctx_color}${ctx_in_h:-0}${c_reset}${c_dim}in/${ctx_out_h:-0}out${c_reset}")
fi

if [ -n "$cache_read" ] || [ -n "$cache_write" ]; then
  cache_hit="$(awk -v r="${cache_read:-0}" -v f="${cache_fresh:-0}" -v w="${cache_write:-0}" \
    'BEGIN { t=r+f+w; if (t>0) printf "%d", (r/t)*100 }')"
  cache_read_h="$(fmt_k "$cache_read")"
  cache_write_h="$(fmt_k "$cache_write")"
  # green > 70% hit > 30% > red
  cache_color="$(color_low "${cache_hit:-0}" 70 30)"
  parts+=("${c_dim}cache:${c_reset}${cache_color}${cache_hit:-0}%${c_reset} ${c_dim}(${cache_read_h:-0}rd/${cache_write_h:-0}wr)${c_reset}")
fi

if [ -n "$rl_5h_pct" ]; then
  rl_5h_pct_r="$(awk -v p="$rl_5h_pct" 'BEGIN { printf "%d", p }')"
  rl_5h_color="$(color_high "$rl_5h_pct_r" 50 80)"
  rl_5h_reset_h="$(fmt_reset "$rl_5h_reset")"
  parts+=("${c_dim}5h:${c_reset}${rl_5h_color}${rl_5h_pct_r}%${c_reset}${c_dim}${rl_5h_reset_h:+ (${rl_5h_reset_h})}${c_reset}")
fi

if [ -n "$rl_7d_pct" ]; then
  rl_7d_pct_r="$(awk -v p="$rl_7d_pct" 'BEGIN { printf "%d", p }')"
  rl_7d_color="$(color_high "$rl_7d_pct_r" 50 80)"
  rl_7d_reset_h="$(fmt_reset "$rl_7d_reset")"
  parts+=("${c_dim}7d:${c_reset}${rl_7d_color}${rl_7d_pct_r}%${c_reset}${c_dim}${rl_7d_reset_h:+ (${rl_7d_reset_h})}${c_reset}")
fi

[ -n "$cost" ] && parts+=("${c_dim}cost:${c_reset}${c_yellow}\$$cost${c_reset}")
[ -n "$thinking" ] && parts+=("${c_dim}thinking:${thinking}${c_reset}")
[ -n "$mode" ] && parts+=("${c_dim}mode:${mode}${c_reset}")

sep="${c_dim} | ${c_reset}"
printf '%s' "${parts[0]}"
for part in "${parts[@]:1}"; do
  printf '%s%s' "$sep" "$part"
done
printf '\n'
