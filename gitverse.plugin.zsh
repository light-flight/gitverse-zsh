# GitVerse zsh helpers.
#
# Public commands:
# - jco: create a ticket-prefixed branch
# - gpp: push current branch and create a GitVerse pull request

if [[ -n "${ZSH_VERSION:-}" ]]; then
  __gitverse_plugin_dir="${${(%):-%N}:A:h}"
  if [[ -d "$__gitverse_plugin_dir/completions" ]]; then
    fpath=("$__gitverse_plugin_dir/completions" $fpath)
    if (( $+functions[compdef] )); then
      autoload -Uz _gpp _jco
      compdef _gpp gpp
      compdef _jco jco
    fi
  fi
  unset __gitverse_plugin_dir
fi

__gitverse_ticket_regex() {
  printf "%s\n" "TSKFRMRVR-[0-9]+"
}

__gitverse_host() {
  printf "%s\n" "${GITVERSE_HOST:-gitverse.ru}"
}

__gitverse_api_url() {
  printf "%s\n" "${GITVERSE_API_URL:-https://api.gitverse.ru}"
}

__gitverse_default_base_branch() {
  printf "%s\n" "${GITVERSE_DEFAULT_BASE_BRANCH:-main}"
}

__gitverse_require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is required" >&2
    return 1
  fi
}

__gitverse_ticket() {
  local input="$1"
  local regex

  regex="$(__gitverse_ticket_regex)"
  printf "%s\n" "$input" | grep -oE "$regex" | head -n 1
}

__gitverse_branch_title() {
  local branch="$1"
  local branch_title

  branch_title="${branch##*/}"
  printf "%s\n" "${branch_title//-/ }"
}

__gitverse_parse_remote() {
  local remote_url="$1"
  local host remote_path owner repo

  host="$(__gitverse_host)"

  case "$remote_url" in
    git@${host}:*)
      remote_path="${remote_url#git@${host}:}"
      ;;
    ssh://git@${host}/*)
      remote_path="${remote_url#ssh://git@${host}/}"
      ;;
    https://${host}/*)
      remote_path="${remote_url#https://${host}/}"
      ;;
    http://${host}/*)
      remote_path="${remote_url#http://${host}/}"
      ;;
    *)
      echo "origin is not a GitVerse remote: $remote_url" >&2
      return 1
      ;;
  esac

  remote_path="${remote_path%.git}"
  owner="${remote_path%%/*}"
  repo="${remote_path#*/}"

  if [[ -z "$owner" || -z "$repo" || "$owner" == "$repo" ]]; then
    echo "Could not parse GitVerse owner/repo from origin: $remote_url" >&2
    return 1
  fi

  printf "%s\n%s\n" "$owner" "$repo"
}

__gitverse_base_branch() {
  local base_branch

  base_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
  base_branch="${base_branch#origin/}"

  if [[ -z "$base_branch" ]]; then
    base_branch="$(__gitverse_default_base_branch)"
  fi

  printf "%s\n" "$base_branch"
}

__gitverse_pr_body() {
  local ticker="$1"
  local issue_number

  if [[ -z "$ticker" ]]; then
    return 0
  fi

  issue_number="${ticker##*-}"
  printf "Closes #%s\n\nRelated to %s" "$issue_number" "$ticker"
}

__gitverse_pr_payload() {
  local title="$1"
  local head="$2"
  local base="$3"
  local body="$4"

  GV_TITLE="$title" GV_HEAD="$head" GV_BASE="$base" GV_BODY="$body" python3 - <<'PY'
import json
import os

payload = {
    "title": os.environ["GV_TITLE"],
    "head": os.environ["GV_HEAD"],
    "base": os.environ["GV_BASE"],
}

body = os.environ.get("GV_BODY")
if body:
    payload["body"] = body

print(json.dumps(payload))
PY
}

__gitverse_extract_pr_url() {
  local response_body="$1"

  GV_RESPONSE="$response_body" python3 - <<'PY'
import json
import os
import sys

try:
    response = json.loads(os.environ["GV_RESPONSE"])
except json.JSONDecodeError:
    sys.exit(0)

for key in ("html_url", "url"):
    value = response.get(key)
    if isinstance(value, str) and value:
        print(value)
        break
PY
}

__gitverse_jco_usage() {
  echo "Usage: jco <issue-or-text> <branch-title>" >&2
}

__gitverse_gpp_usage() {
  echo "Usage: gpp [-d]" >&2
}

jco() {
  local source_text="$1"
  local branch_title="$2"
  local ticker

  if (( $# != 2 )) || [[ -z "$source_text" || -z "$branch_title" ]]; then
    __gitverse_jco_usage
    return 1
  fi

  __gitverse_require_command git || return $?
  __gitverse_require_command grep || return $?
  __gitverse_require_command head || return $?

  ticker="$(__gitverse_ticket "$source_text")"
  if [[ -z "$ticker" ]]; then
    echo "Could not find ticket in: $source_text" >&2
    return 1
  fi

  git checkout -b "$ticker/$branch_title"
}

gpp() {
  local branch ticker branch_title pr_title pr_body draft
  local remote_url owner repo base_branch payload response_file response_body http_status pr_url
  local curl_status option remote_parse_output remote_parts
  local OPTIND=1

  while getopts "dh" option; do
    case "$option" in
      d)
        draft=1
        ;;
      h)
        __gitverse_gpp_usage
        return 0
        ;;
      *)
        __gitverse_gpp_usage
        return 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  if (( $# > 0 )); then
    __gitverse_gpp_usage
    return 1
  fi

  __gitverse_require_command git || return $?
  __gitverse_require_command grep || return $?
  __gitverse_require_command head || return $?
  __gitverse_require_command python3 || return $?
  __gitverse_require_command curl || return $?

  if [[ -z "$GITVERSE_TOKEN" ]]; then
    echo "GITVERSE_TOKEN is not set" >&2
    return 1
  fi

  branch="$(git branch --show-current)"
  if [[ -z "$branch" ]]; then
    echo "Could not detect current git branch" >&2
    return 1
  fi

  remote_url="$(git remote get-url origin 2>/dev/null)"
  if [[ -z "$remote_url" ]]; then
    echo "Could not read origin remote" >&2
    return 1
  fi

  remote_parse_output="$(__gitverse_parse_remote "$remote_url")" || return $?
  remote_parts=("${(@f)remote_parse_output}")
  owner="${remote_parts[1]}"
  repo="${remote_parts[2]}"

  ticker="$(__gitverse_ticket "$branch")"
  branch_title="$(__gitverse_branch_title "$branch")"
  pr_title="$branch_title"
  pr_body="$(__gitverse_pr_body "$ticker")"

  if [[ -n "$ticker" ]]; then
    pr_title="[$ticker] $pr_title"
  fi

  if [[ -n "$draft" ]]; then
    pr_title="Draft: $pr_title"
  fi

  base_branch="$(__gitverse_base_branch)"
  payload="$(__gitverse_pr_payload "$pr_title" "$branch" "$base_branch" "$pr_body")"

  if [[ "$GITVERSE_SKIP_PUSH" != "1" ]]; then
    git push -u origin HEAD || return $?
  fi

  response_file="$(mktemp)"
  http_status="$(curl -sS -o "$response_file" -w "%{http_code}" \
    -X POST "$(__gitverse_api_url)/repos/$owner/$repo/pulls" \
    -H "Authorization: Bearer $GITVERSE_TOKEN" \
    -H "Accept: application/vnd.gitverse.object+json;version=1" \
    -H "Content-Type: application/json" \
    -d "$payload")"
  curl_status=$?
  response_body="$(<"$response_file")"
  rm -f "$response_file"

  if [[ "$curl_status" -ne 0 ]]; then
    return "$curl_status"
  fi

  if [[ "$http_status" != 2* ]]; then
    echo "GitVerse PR creation failed (HTTP $http_status):" >&2
    echo "$response_body" >&2
    return 1
  fi

  pr_url="$(__gitverse_extract_pr_url "$response_body")"
  if [[ -n "$pr_url" ]]; then
    echo "Created GitVerse PR: $pr_url"
  else
    echo "Created GitVerse PR:"
    echo "$response_body"
  fi
}
