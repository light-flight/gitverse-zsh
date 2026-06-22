#!/usr/bin/env zsh

set -u

plugin_dir="${0:A:h:h}"
failures=0

fail() {
  echo "not ok - $1" >&2
  failures=$((failures + 1))
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "$actual" == "$expected" ]]; then
    echo "ok - $message"
  else
    fail "$message: expected '$expected', got '$actual'"
  fi
}

source "$plugin_dir/gitverse.plugin.zsh"

if (( $+functions[jco] )); then
  echo "ok - jco is defined"
else
  fail "jco is defined"
fi

if (( $+functions[gpp] )); then
  echo "ok - gpp is defined"
else
  fail "gpp is defined"
fi

assert_eq "$(__gitverse_ticket "fix TSKFRMRVR-42 workspace")" "TSKFRMRVR-42" "extracts default ticket"
assert_eq "$(__gitverse_branch_title "TSKFRMRVR-42/fix-workspace-export")" "fix workspace export" "builds branch title"

remote_parts=("${(@f)$(__gitverse_parse_remote "git@gitverse.ru:team/repo.git")}")
assert_eq "${remote_parts[1]}" "team" "parses SSH remote owner"
assert_eq "${remote_parts[2]}" "repo" "parses SSH remote repo"

remote_parts=("${(@f)$(__gitverse_parse_remote "https://gitverse.ru/team/repo.git")}")
assert_eq "${remote_parts[1]}" "team" "parses HTTPS remote owner"
assert_eq "${remote_parts[2]}" "repo" "parses HTTPS remote repo"

payload="$(__gitverse_pr_payload "[TSKFRMRVR-42] fix workspace export" "TSKFRMRVR-42/fix-workspace-export" "main" "Closes #42")"
payload_title="$(GV_PAYLOAD="$payload" python3 - <<'PY'
import json
import os

print(json.loads(os.environ["GV_PAYLOAD"])["title"])
PY
)"
assert_eq "$payload_title" "[TSKFRMRVR-42] fix workspace export" "builds JSON payload"

assert_eq "$(__gitverse_extract_pr_url '{"html_url":"https://gitverse.ru/team/repo/pulls/1"}')" "https://gitverse.ru/team/repo/pulls/1" "extracts PR URL"

if (( failures > 0 )); then
  echo "$failures smoke test(s) failed" >&2
  exit 1
fi

echo "all smoke tests passed"
