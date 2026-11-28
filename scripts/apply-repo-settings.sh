#!/usr/bin/env bash
# Apply or check the standard GitHub settings for this repository.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/apply-repo-settings.sh [--check]

Without --check, apply the standard settings and verify them.
With --check, report drift without changing anything.
EOF
}

if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi

mode=apply
case "${1:-}" in
  "") ;;
  --check) mode=check ;;
  -h|--help) usage; exit 0 ;;
  *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
esac

OWNER="${OWNER:-$(gh repo view --json owner --jq .owner.login)}"
REPO="${REPO:-$(basename "$(git rev-parse --show-toplevel)")}"
API="repos/$OWNER/$REPO"

case "$REPO" in
  forscore-setlist)
    DESCRIPTION="Convert forScore setlists and text lists into Open Setlist .4ss files."
    TOPICS='["go","forscore","setlist","cli","music"]'
    ;;
  forscore-metadata)
    DESCRIPTION="Write forScore-ready metadata into score PDFs from filenames."
    TOPICS='["go","forscore","pdf","metadata","cli","music"]'
    ;;
  scan2pdf)
    DESCRIPTION="Turn numbered scan images into a print-ready PDF."
    TOPICS='["go","pdf","scanning","cli"]'
    ;;
  *)
    echo "Unknown repository: $REPO" >&2
    exit 1
    ;;
esac

DRIFT=0

check_eq() {
  local label="$1" current="$2" desired="$3"
  if [ "$current" = "$desired" ]; then
    printf '  ok       %s = %s\n' "$label" "$current"
  else
    printf '  DRIFT    %s = %s (want %s)\n' "$label" "$current" "$desired"
    DRIFT=$((DRIFT + 1))
  fi
}

run_checks() {
  DRIFT=0
  local repo_json ruleset_id ruleset permissions workflow current

  repo_json="$(gh api "$API")" || {
    echo "Unable to read repository settings." >&2
    return 1
  }

  check_eq "description" "$(jq -r '.description // ""' <<<"$repo_json")" "$DESCRIPTION"
  check_eq "topics" "$(jq -r '.topics | sort | join(",")' <<<"$repo_json")" "$(jq -r 'sort | join(",")' <<<"$TOPICS")"
  check_eq "default branch" "$(jq -r '.default_branch' <<<"$repo_json")" "main"
  check_eq "wiki" "$(jq -r '.has_wiki' <<<"$repo_json")" "false"
  check_eq "projects" "$(jq -r '.has_projects' <<<"$repo_json")" "false"
  check_eq "discussions" "$(jq -r '.has_discussions' <<<"$repo_json")" "false"
  check_eq "squash merge" "$(jq -r '.allow_squash_merge' <<<"$repo_json")" "true"
  check_eq "merge commits" "$(jq -r '.allow_merge_commit' <<<"$repo_json")" "false"
  check_eq "rebase merge" "$(jq -r '.allow_rebase_merge' <<<"$repo_json")" "false"
  check_eq "delete branch on merge" "$(jq -r '.delete_branch_on_merge' <<<"$repo_json")" "true"
  check_eq "update branch" "$(jq -r '.allow_update_branch' <<<"$repo_json")" "true"
  check_eq "secret scanning" "$(jq -r '.security_and_analysis.secret_scanning.status // "disabled"' <<<"$repo_json")" "enabled"
  check_eq "push protection" "$(jq -r '.security_and_analysis.secret_scanning_push_protection.status // "disabled"' <<<"$repo_json")" "enabled"

  if gh api "$API/vulnerability-alerts" >/dev/null 2>&1; then
    current="enabled"
  else
    current="disabled"
  fi
  check_eq "vulnerability alerts" "$current" "enabled"

  current="$(gh api "$API/automated-security-fixes" --jq '.enabled' 2>/dev/null || echo false)"
  check_eq "automated security fixes" "$current" "true"

  permissions="$(gh api "$API/actions/permissions")" || {
    echo "Unable to read Actions permissions." >&2
    return 1
  }
  check_eq "actions enabled" "$(jq -r '.enabled' <<<"$permissions")" "true"
  check_eq "allowed actions" "$(jq -r '.allowed_actions' <<<"$permissions")" "all"
  check_eq "SHA-pinned actions" "$(jq -r '.sha_pinning_required' <<<"$permissions")" "true"

  workflow="$(gh api "$API/actions/permissions/workflow")" || {
    echo "Unable to read workflow permissions." >&2
    return 1
  }
  check_eq "workflow token" "$(jq -r '.default_workflow_permissions' <<<"$workflow")" "read"
  check_eq "workflow PR approval" "$(jq -r '.can_approve_pull_request_reviews' <<<"$workflow")" "false"

  ruleset_id="$(gh api "$API/rulesets" --jq '.[] | select(.name == "main branch ruleset") | .id' 2>/dev/null | head -1)"
  if [ -z "$ruleset_id" ]; then
    printf '  DRIFT    main branch ruleset is missing\n'
    DRIFT=$((DRIFT + 1))
  else
    ruleset="$(gh api "$API/rulesets/$ruleset_id")"
    check_eq "ruleset enforcement" "$(jq -r '.enforcement' <<<"$ruleset")" "active"
    check_eq "ruleset target" "$(jq -r '.target' <<<"$ruleset")" "branch"
    check_eq "ruleset default branch" "$(jq -r '.conditions.ref_name.include | index("~DEFAULT_BRANCH") != null' <<<"$ruleset")" "true"
    for rule in deletion non_fast_forward pull_request required_linear_history; do
      check_eq "rule $rule" "$(jq -r --arg rule "$rule" '[.rules[].type] | index($rule) != null' <<<"$ruleset")" "true"
    done
    check_eq "required status check" "$(jq -r '[.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context] | sort | join(",")' <<<"$ruleset")" "CI gate"
    check_eq "strict status checks" "$(jq -r '[.rules[] | select(.type == "required_status_checks") | .parameters.strict_required_status_checks_policy] | first // false' <<<"$ruleset")" "true"
    check_eq "required approvals" "$(jq -r '[.rules[] | select(.type == "pull_request") | .parameters.required_approving_review_count] | first // 0' <<<"$ruleset")" "0"
  fi

  if [ "$DRIFT" -ne 0 ]; then
    echo "Drift detected: $DRIFT setting(s) do not match." >&2
    return 1
  fi
  echo "All repository settings match."
}

apply() {
  echo "Applying repository settings to $OWNER/$REPO"

  gh api -X PATCH "$API" --input - <<JSON
{
  "description": "$DESCRIPTION",
  "homepage": "",
  "has_wiki": false,
  "has_projects": false,
  "has_discussions": false,
  "delete_branch_on_merge": true,
  "allow_update_branch": true,
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false,
  "security_and_analysis": {
    "secret_scanning": {"status": "enabled"},
    "secret_scanning_push_protection": {"status": "enabled"}
  }
}
JSON

  gh api -X PUT "$API/topics" --input - <<JSON
{"names": $TOPICS}
JSON

  gh api -X PUT "$API/vulnerability-alerts" >/dev/null
  gh api -X PUT "$API/automated-security-fixes" >/dev/null

  gh api -X PUT "$API/actions/permissions" --input - <<'JSON'
{"enabled": true, "allowed_actions": "all", "sha_pinning_required": true}
JSON

  gh api -X PUT "$API/actions/permissions/workflow" --input - <<'JSON'
{"default_workflow_permissions": "read", "can_approve_pull_request_reviews": false}
JSON

  local ruleset_id
  ruleset_id="$(gh api "$API/rulesets" --jq '.[] | select(.name == "main branch ruleset") | .id')"
  if [ -z "$ruleset_id" ]; then
    echo "main branch ruleset not found" >&2
    exit 1
  fi

  gh api "$API/rulesets/$ruleset_id" | jq '{
    name, target, enforcement, conditions,
    bypass_actors: (.bypass_actors // []),
    rules: (.rules | map(
      if .type == "required_status_checks" then
        .parameters.required_status_checks = [{"context": "CI gate"}]
      else . end
    ))
  }' | gh api -X PUT "$API/rulesets/$ruleset_id" --input - >/dev/null
}

if [ "$mode" = check ]; then
  echo "Checking repository settings for $OWNER/$REPO"
  run_checks
  exit $?
fi

apply
echo
run_checks
