# Sync Upstream Repo Fork

This is a Github Action used to merge changes from remote.  

This is forked from [mheene](https://github.com/mheene/sync-upstream-repo), with me adding authentication using [GitHub Token](https://docs.github.com/en/actions/reference/authentication-in-a-workflow) and downstream branch options due to the [default branch naming changes](https://github.com/github/renaming).

## Use case

- Perserve a repo while keeping up-to-date (rather than to clone it).
- Have a branch in sync with upstream, and pull changes into dev branch.

## Usage

Example github action [here](https://github.com/THIS-IS-NOT-A-BACKUP/go-web-proxy/blob/main/.github/workflows/sync5.yml):

```YAML
name: My_Pipeline_Name

### 
env:
  # Required, URL to upstream (fork base)
  UPSTREAM_URL: "https://github.com/dabreadman/go-web-proxy.git"
  # Optional, defaults to main
  DOWNSTREAM_BRANCH: "main"
### 

on:
  schedule:
    - cron: '30 * * * *'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: GitHub Sync to Upstream Repository
        uses: dabreadman/sync-upstream-repo@v0.1.2.b
        with: 
          upstream_repo: ${{ env.UPSTREAM_URL }}
          branch: $$ env.DOWNSTREAM_BRANCH }}
          token: ${{ secrets.GITHUB_TOKEN}}
```

This action syncs your repo (merge changes from `remote`) at branch `main` with the upstream repo ``` https://github.com/dabreadman/go-web-proxy.git ``` every 30 minutes.

## Mechanism

1. Setup an environment using docker.
  (Why do that when `Workflow` is inside an environment? I have no idea).
2. Pass arguments into `entrypoint.sh`.
3. `entrypoint.sh` does the heavy lifting.  
  git clone, set origin/upstream, fetch, merge, push.
