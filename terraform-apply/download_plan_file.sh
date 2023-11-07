#!/usr/bin/env bash

set -euo pipefail

filename=tfplan.binary
artifact_name=terraform_plan_file_${TFACTION_TARGET//\//__}
branch=$CI_INFO_HEAD_REF
workflow=$PLAN_WORKFLOW_NAME

pr_head_sha=$(jq -r ".head.sha" "$CI_INFO_TEMP_DIR/pr.json")

pwd
ls -al
ls -al .github/workflows
echo "before run list"
gh run list -w "$workflow" -b "$branch" -L 1 --json headSha,databaseId --jq '.[0]'
body=$(gh run list -w "$workflow" -b "$branch" -L 1 --json headSha,databaseId --jq '.[0]')
echo $body

run_id=$(echo "$body" | jq -r ".databaseId")
echo $run_id
head_sha=$(echo "$body" | jq -r ".headSha")
echo $head_sha
echo "after run list"

if [ "$head_sha" != "$pr_head_sha" ]; then
	echo "::error::workflow run's headSha is different from the associated pull request's head sha"
	github-comment post -k invalid-workflow-sha \
		-var "wf_sha:$head_sha" -var "pr_sha:$pr_head_sha"
	exit 1
fi

tempdir=$(mktemp -d)
echo "before inner download"
gh run download -D "$tempdir" -n "$artifact_name" "$run_id"
echo "after inner downlaod"
cp "$tempdir/$filename" tfplan.binary
