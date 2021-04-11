#!/usr/bin/env bash

set -x

UPSTREAM_REPO=$1
BRANCH=$2
GITHUB_TOKEN=$3
MERGE_ARGS=$4
PUSH_ARGS=$5

if [[ -z "$UPSTREAM_REPO" ]]; then
  echo "Missing \$UPSTREAM_REPO"
  exit 1
fi

if ! echo "$UPSTREAM_REPO" | grep '\.git'; then
  UPSTREAM_REPO="https://github.com/${UPSTREAM_REPO_PATH}.git"
fi

echo "UPSTREAM_REPO=$UPSTREAM_REPO"

git clone "https://github.com/${GITHUB_REPOSITORY}.git" work
cd work || { echo "Missing work dir" && exist 2 ; }

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --local user.password ${GITHUB_TOKEN}

git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

git remote add upstream "$UPSTREAM_REPO"
git fetch --all
git remote -v

git checkout ${BRANCH}

MERGE_RESULT=$(git merge upstream/${BRANCH} ${MERGE_ARGS})
if [[ $MERGE_RESULT != *"Already up to date."* ]]; then
  git commit -m "Merged upstream"  
  git push origin ${BRANCH} ${PUSH_ARGS} || exit $?
fi

cd ..
rm -rf work
