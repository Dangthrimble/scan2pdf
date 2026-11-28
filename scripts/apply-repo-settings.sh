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

if [ ! -f repository.json ]; then
  echo "repository.json is required; it supplies the description and topics." >&2
  exit 1
fi
DESCRIPTION="$(jq -r '.description // ""' repository.json)"
TOPICS="$(jq -c '.topics // []' repository.json)"
ISSUES="$(jq -r 'if has("issues") then .issues else true end' repository.json)"
DISCUSSIONS="$(jq -r 'if has("discussions") then .discussions else false end' repository.json)"

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
  local repo_json rulesets_json ruleset_id ruleset permissions workflow current

  repo_json="$(gh api "$API")" || {
    echo "Unable to read repository settings." >&2
    return 1
  }

  check_eq "description" "$(jq -r '.description // ""' <<<"$repo_json")" "$DESCRIPTION"
  if [ "$(jq -r '.visibility' <<<"$repo_json")" = "public" ]; then
    check_eq "topics" "$(jq -r '.topics | sort | join(",")' <<<"$repo_json")" "$(jq -r 'sort | join(",")' <<<"$TOPICS")"
  else
    printf '  skip     topics (private repository)\n'
  fi
  check_eq "default branch" "$(jq -r '.default_branch' <<<"$repo_json")" "main"
  check_eq "wiki" "$(jq -r '.has_wiki' <<<"$repo_json")" "false"
  check_eq "issues" "$(jq -r '.has_issues' <<<"$repo_json")" "$ISSUES"
  check_eq "projects" "$(jq -r '.has_projects' <<<"$repo_json")" "false"
  check_eq "discussions" "$(jq -r '.has_discussions' <<<"$repo_json")" "$DISCUSSIONS"
  check_eq "squash merge" "$(jq -r '.allow_squash_merge' <<<"$repo_json")" "true"
  check_eq "merge commits" "$(jq -r '.allow_merge_commit' <<<"$repo_json")" "false"
  check_eq "rebase merge" "$(jq -r '.allow_rebase_merge' <<<"$repo_json")" "false"
  check_eq "delete branch on merge" "$(jq -r '.delete_branch_on_merge' <<<"$repo_json")" "true"
  check_eq "update branch" "$(jq -r '.allow_update_branch' <<<"$repo_json")" "true"
  if [ "$(jq -r '.visibility' <<<"$repo_json")" = "public" ]; then
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
  else
    printf '  skip     secret scanning, push protection and Dependabot alerts (private repository)\n'
  fi

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

  if ! rulesets_json="$(gh api "$API/rulesets" 2>/dev/null)"; then
    printf '  skip     main branch ruleset (unavailable on this plan)\n'
  elif [ -z "$(jq -r '.[] | select(.name == "main branch ruleset") | .id' <<<"$rulesets_json" | head -1)" ]; then
    printf '  DRIFT    main branch ruleset is missing\n'
    DRIFT=$((DRIFT + 1))
  else
    ruleset_id="$(jq -r '.[] | select(.name == "main branch ruleset") | .id' <<<"$rulesets_json" | head -1)"
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

  local visibility
  visibility="$(gh api "$API" --jq '.visibility')"
  if [ "$visibility" = "public" ]; then
    gh api -X PATCH "$API" --input - >/dev/null <<JSON
{
  "description": "$DESCRIPTION",
  "homepage": "",
  "has_wiki": false,
  "has_issues": $ISSUES,
  "has_projects": false,
  "has_discussions": $DISCUSSIONS,
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
  else
    gh api -X PATCH "$API" --input - <<JSON >/dev/null
{
  "description": "$DESCRIPTION",
  "homepage": "",
  "has_wiki": false,
  "has_issues": $ISSUES,
  "has_projects": false,
  "has_discussions": $DISCUSSIONS,
  "delete_branch_on_merge": true,
  "allow_update_branch": true,
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false
}
JSON
  fi

  local topics_json
  topics_json="{\"names\": $TOPICS}"
  if [ "$visibility" = "public" ]; then
    echo "$topics_json" | gh api -X PUT "$API/topics" --input - >/dev/null
  elif ! echo "$topics_json" | gh api -X PUT "$API/topics" --input - >/dev/null 2>&1; then
    echo "  note: topics are unavailable for this private repository" >&2
  fi

  gh api -X PUT "$API/vulnerability-alerts" >/dev/null 2>&1 || \
    echo "  note: vulnerability alerts are unavailable for this private repository" >&2
  gh api -X PUT "$API/automated-security-fixes" >/dev/null 2>&1 || \
    echo "  note: automated security fixes are unavailable for this private repository" >&2

  gh api -X PUT "$API/actions/permissions" --input - <<'JSON'
{"enabled": true, "allowed_actions": "all", "sha_pinning_required": true}
JSON

  gh api -X PUT "$API/actions/permissions/workflow" --input - <<'JSON'
{"default_workflow_permissions": "read", "can_approve_pull_request_reviews": false}
JSON

  local ruleset_id rulesets_json
  if ! rulesets_json="$(gh api "$API/rulesets" 2>/dev/null)"; then
    echo "  note: rulesets are unavailable for this private repository on the current plan" >&2
    return 0
  fi
  ruleset_id="$(jq -r '.[] | select(.name == "main branch ruleset") | .id' <<<"$rulesets_json" | head -1)"
  if [ -z "$ruleset_id" ]; then
    gh api -X POST "$API/rulesets" --input - >/dev/null <<'JSON'
{
  "name": "main branch ruleset",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}
  },
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true,
        "allowed_merge_methods": ["squash"]
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [{"context": "CI gate"}],
        "strict_required_status_checks_policy": true
      }
    },
    {"type": "required_linear_history"}
  ]
}
JSON
  else
    gh api "$API/rulesets/$ruleset_id" | jq '{
      name, target, enforcement, conditions,
      bypass_actors: (.bypass_actors // []),
      rules: (.rules | map(
        if .type == "required_status_checks" then
          .parameters.required_status_checks = [{"context": "CI gate"}]
        else . end
      ))
    }' | gh api -X PUT "$API/rulesets/$ruleset_id" --input - >/dev/null
  fi
}

if [ "$mode" = check ]; then
  echo "Checking repository settings for $OWNER/$REPO"
  run_checks
  exit $?
fi

apply
echo
run_checks
