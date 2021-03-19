# Sync Upstream Repo Fork

This repository contains an github action to sync your current repository with an upstream repository. The work is greatly inspired by [actions-registry/github-repo-sync-upstream](https://github.com/actions-registry/github-repo-sync-upstream) which didn't work for me.
Added parameter to determine target branch.

## Usage

Example github action:

```YAML
name: CI

on: 
  schedule:
    - cron: "15 14 * * *"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: GitHub Sync to Upstream Repository
      uses: dabreadman/sync-upstream-repo@v0.1.2.b
      with:
      # GitHub public upstream repo
        upstream_repo: https://github.com/holger24/AFD.git 
        branch: main
```

This action syncs your repo at branch `main` with the upstream repo ``` https://github.com/holger24/AFD.git ``` every day at 14:15 UTC.
