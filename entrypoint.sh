#!/usr/bin/env bash

set -e

readonly GIT_REPO_REGEX="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+)(.git)*$"
UPSTREAM_REPO_URL=${1}
UPSTREAM_BRANCH=${2}
DOWNSTREAM_REPO_URL=${3}
DOWNSTREAM_BRANCH=${4}
GITHUB_TOKEN=${5}
MERGE_STRATEGY=${6}
SPAWN_LOGS=${7}
FETCH_ARGS=${8}
REBASE_ARGS=${9}
PUSH_ARGS=${10}
MERGE_ARGS=${11}


function do_merge() {
  case ${SPAWN_LOGS} in
   (true)    echo -n "sync-upstream-repo keeping CI alive."\
             "UNIX Time: " >> sync-upstream-repo
             date +"%s" >> sync-upstream-repo
             git add sync-upstream-repo
             git commit sync-upstream-repo -m "Syncing upstream";;
   (false)   echo "Not spawning time logs"
  esac
  local merge_result=$(git merge ${MERGE_ARGS} upstream/${UPSTREAM_BRANCH})
  if [[ $merge_result == "" ]]; then
      exit 1
  elif [[ $merge_result != *"Already up to date."* ]]; then
      git commit -m "Merged upstream"
  fi
}
function apply_merge_strategy() {
  if [[ ${MERGE_STRATEGY} == "rebase" ]]; then 
    echo "Rebasing upstream/${UPSTREAM_BRANCH} unto ${DOWNSTREAM_BRANCH}"
    git rebase ${REBASE_ARGS} upstream/${UPSTREAM_BRANCH}
  elif [[ ${MERGE_STRATEGY} == "merge" ]]; then
    echo "Merging upstream/${UPSTREAM_BRANCH} unto ${DOWNSTREAM_BRANCH}"
    do_merge
  else
    echo "Unknown merge strategy: $MERGE_STRATEGY"
    exit 1
  fi
}

if [[ -z "${UPSTREAM_REPO_URL}" ]]; then
  echo "Missing UPSTREAM_REPO"
  exit 1
fi

if [[ -z "${UPSTREAM_BRANCH}" ]]; then
  echo "Missing UPSTREAM_BRANCH"
  exit 1
fi

if [[ -z "${DOWNSTREAM_REPO_URL}" ]]; then
  echo "Missing DOWNSTREAM_REPO_URL"
  exit 1
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
  echo "Missing GITHUB_TOKEN"
  exit 1
fi

if [[ -z "${MERGE_STRATEGY}" ]]; then
  echo "MERGE_STRATEGY not set, defaulting to 'rebase' strategy"
  MERGE_STRATEGY="rebase"
fi

if [[ -z "${DOWNSTREAM_BRANCH}" ]]; then
  echo "Missing DOWNSTREAM_BRANCH, defaulting it to ${UPSTREAM_BRANCH}"
  DOWNSTREAM_BRANCH=${UPSTREAM_BRANCH}
fi

if [[ -z "${SPAWN_LOGS}" ]]; then
  echo "Defaulting SPAWN_LOGS to false"
  SPAWN_LOGS="false"
fi 

echo "Running with these values:"
echo "    UPSTREAM_REPO_URL='${UPSTREAM_REPO_URL}'"
echo "    UPSTREAM_BRANCH='${UPSTREAM_BRANCH}'"
echo "    DOWNSTREAM_REPO_URL='${DOWNSTREAM_REPO_URL}'"
echo "    DOWNSTREAM_BRANCH='${DOWNSTREAM_BRANCH}'"
echo "    GITHUB_TOKEN=*******"
echo "    MERGE_STRATEGY='${MERGE_STRATEGY}'"
echo "    SPAWN_LOGS='${SPAWN_LOGS}'"
echo "    FETCH_ARGS='${FETCH_ARGS}'"
echo "    REBASE_ARGS='${REBASE_ARGS}'"
echo "    PUSH_ARGS='${PUSH_ARGS}'"
echo "    MERGE_ARGS='${MERGE_ARGS}'"

if [[ ${DOWNSTREAM_REPO_URL} =~ ${GIT_REPO_REGEX} ]]; then    
  DOWNSTREAM_REPO="${BASH_REMATCH[4]}/${BASH_REMATCH[5]}"
  if [[ -z "${GITHUB_ACTOR}" ]]; then
    GITHUB_ACTOR=${BASH_REMATCH[4]}
  fi
else 
  echo "${DOWNSTREAM_REPO_URL} does not seem to be a valid GitHub repo url"
  exit 1
fi

mkdir -pv work
if [[ $? -gt 0 ]]; then
  echo "Failed to create work directory"
  exit 1
fi 

git clone "https://github.com/${DOWNSTREAM_REPO}" work
cd work || { echo "Missing work dir" && exit 2 ; }

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --local user.password ${GITHUB_TOKEN}
git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${DOWNSTREAM_REPO}"
git remote add upstream "$UPSTREAM_REPO_URL"
git fetch --quiet --tags ${FETCH_ARGS} upstream

DOWNSTREAM_BRANCH_EXISTS=(`git ls-remote --heads origin refs/heads/${DOWNSTREAM_BRANCH} | wc -l`)
# If the branch exists in origin
if [[ ${DOWNSTREAM_BRANCH_EXISTS} -eq 1 ]]; then
  echo ${DOWNSTREAM_BRANCH} branch exists
  git checkout ${DOWNSTREAM_BRANCH}
  apply_merge_strategy
else 
  echo ${DOWNSTREAM_BRANCH} branch does not exist
  # create new branch with ${DOWNSTREA_BRANCH} name tracking the ${UPSTREAM_BRANCH}
  # this allows for a maping upstream branches to a known branch
  git checkout -b ${DOWNSTREAM_BRANCH} remotes/upstream/${UPSTREAM_BRANCH}
fi


echo "Pushing changes to origin"
git push ${PUSH_ARGS} --follow-tags origin ${DOWNSTREAM_BRANCH}

cd ..
rm -rf work