#!/bin/bash

INPUT_FILE="repos.txt"

timestamp=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="repo_audit_results_${timestamp}.csv"

# CSV header
echo "repo_name,repo_url,owners,active,has_secrets,has_vars,has_code,migrated,updated_at" > "$OUTPUT_FILE"

index=1
while IFS= read -r repo_url; do
  [[ -z "$repo_url" ]] && continue

  # --- Clean repo name
  repo_name=$(basename "$repo_url" | tr -d '\r\n\t ')
  full_name="Nexon-Asia-Pacific-Pty-Ltd/$repo_name"

  echo "[$index] 🔍 Checking $full_name..."
  index=$((index+1))

  # --- Repo metadata
  info_json=$(gh api repos/$full_name --jq '{archived: .archived, size: .size, updated_at: .updated_at, default_branch: .default_branch}' 2>/dev/null)
  archived=$(echo "$info_json" | jq -r '.archived // "false"')
  updated_at=$(echo "$info_json" | jq -r '.updated_at // "N/A"')
  default_branch=$(echo "$info_json" | jq -r '.default_branch // "main"')
  active=$([ "$archived" = "true" ] && echo "No" || echo "Yes")

  # --- Secrets & Variables
  secrets_count=$(gh api repos/$full_name/actions/secrets --jq '.total_count' 2>/dev/null || echo "0")
  vars_count=$(gh api repos/$full_name/actions/variables --jq '.total_count' 2>/dev/null || echo "0")
  has_secrets=$([ "$secrets_count" -gt 0 ] && echo "Yes" || echo "No")
  has_vars=$([ "$vars_count" -gt 0 ] && echo "Yes" || echo "No")

  # --- Owners (Top 2–3 contributors, exclude Cedrique Cablao and github-actions[bot])
  contributors_json=$(gh api --paginate repos/$full_name/contributors --jq '.[].login' 2>/dev/null)
  if [[ -z "$contributors_json" ]]; then
    contributors_json=$(gh api --paginate repos/$full_name/collaborators --jq '.[].login' 2>/dev/null)
  fi
  owners=$(echo "$contributors_json" | grep -viE "cedrique\.cablao|github-actions\[bot\]" | head -n 3 | paste -sd ", " -)
  owners=${owners:-"N/A"}

  # --- Last commit date
  last_commit_date=$(gh api repos/$full_name/commits --limit 1 --jq '.[0].commit.committer.date' 2>/dev/null)
  if [[ -z "$last_commit_date" || "$last_commit_date" == "null" ]]; then
    diff_days=9999
  else
    last_commit_epoch=$(date -d "$last_commit_date" +%s 2>/dev/null || echo 0)
    now_epoch=$(date +%s)
    diff_days=$(( (now_epoch - last_commit_epoch) / 86400 ))
  fi

  # --- Smarter and safe "has_code" detection -------------------------------
  contents_json=$(gh api repos/$full_name/contents?ref=$default_branch --jq '.[].type' 2>/dev/null)

  dir_count=$(echo "$contents_json" | grep -c "dir" 2>/dev/null | tr -d '[:space:]')
  [[ "$dir_count" =~ ^[0-9]+$ ]] || dir_count=0

  file_names=$(gh api repos/$full_name/contents?ref=$default_branch --jq '.[].name' 2>/dev/null)
  file_count=$(echo "$file_names" | wc -l 2>/dev/null | tr -d '[:space:]')
  [[ "$file_count" =~ ^[0-9]+$ ]] || file_count=0

  non_code_files=$(echo "$file_names" | grep -Eci '^(README|LICENSE|\.gitignore)$' 2>/dev/null | tr -d '[:space:]')
  [[ "$non_code_files" =~ ^[0-9]+$ ]] || non_code_files=0

  meaningful_files=$((file_count - non_code_files))
  if [[ "$meaningful_files" -lt 0 ]]; then meaningful_files=0; fi

  if [[ "$dir_count" -gt 0 ]]; then
    has_code="Yes"
  elif [[ "$meaningful_files" -gt 1 ]]; then
    has_code="Yes"
  else
    has_code="No"
  fi

  if [[ "$diff_days" -gt 180 && "$has_code" == "No" ]]; then
    has_code="No"
  fi

  # --- Migration detection using gh search code (private-safe)
  migrated="No"
  if gh search code "migrate" --repo "$full_name" --json path --limit 1 2>/dev/null | grep -q "path"; then
    migrated="Yes"
  fi

  # --- Append to CSV (properly quoted for Excel)
  echo "\"$repo_name\",\"$repo_url\",\"$owners\",\"$active\",\"$has_secrets\",\"$has_vars\",\"$has_code\",\"$migrated\",\"$updated_at\"" >> "$OUTPUT_FILE"

  sleep 0.6
done < "$INPUT_FILE"

echo "✅ Done! Results saved to $OUTPUT_FILE"
