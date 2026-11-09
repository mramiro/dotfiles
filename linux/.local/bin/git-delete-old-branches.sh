#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

exec 3>&1

yell() { echo "$0: $*" >&2; }

die() { yell "$1"; exit ${2:-255}; }

try() { "$@" || die "cannot $*"; }

log() {
  local msg
  local lvl
  case $# in
    1) lvl=${LOG_LEVEL:-i}
      msg=$1
      ;;
    2) lvl=${1##-}
      msg=$2
      ;;
    *) die "Invalid number of arguments"
      ;;
  esac
  local debug=${DEBUG:-false}
  case "$lvl" in
    d) if [ "$debug" = true ]; then
        echo "$msg" 1>&3
      fi
      ;;
    i) echo "$msg" 1>&3
      ;;
    w) echo "$msg" 1>&3
      ;;
    e) yell "$msg" 1>&3
      ;;
    *) die "Invalid log level"
      ;;
  esac
}

function trim_string() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//g;s/[[:space:]]*$//g'
}

include_remotes=false
dry_run=false
filter=""
while getopts ':f:rn' flag; do
  case $flag in
    f) filter="$OPTARG"
      ;;
    r) include_remotes=true
      ;;
    n) dry_run=true
      ;;
    \?) die "Invalid option: -$OPTARG"
      ;;
    :) die "Invalid option: -$OPTARG requires an argument"
      ;;
  esac
done
shift $((OPTIND -1))

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  die "Not inside a Git repository"
fi

current_branch=${1:-master}
if ! git show-ref --verify --quiet "refs/heads/$current_branch"; then
  die "Local branch '$current_branch' does not exist"
fi

log "Switching to branch: $current_branch"
if $dry_run; then
  log "[DRYRUN]: git checkout $current_branch"
else
  git checkout "$current_branch"
fi
echo "Deleting local branches already merged to $current_branch..."
while IFS= read -r branch; do
  [ -n "$branch" ] || continue
  [ "$branch" = "$current_branch" ] && continue
  if $dry_run; then
    log "[DRYRUN]: git branch -d -- $branch"
  else
    git branch -d -- "$branch"
  fi
done < <(git for-each-ref --merged="$current_branch" --format='%(refname:short)' refs/heads)

if $include_remotes; then
  log "Pulling latest changes into $current_branch"
  if $dry_run; then
    log "[DRYRUN]: git pull"
  else
    git pull
  fi
  log "Pruning stale branches in remotes..."
  while IFS= read -r remote; do
    [ -n "$remote" ] || continue
    if $dry_run; then
      log "[DRYRUN]: git remote prune $remote"
    else
      git remote prune "$remote"
    fi
  done < <(git remote)
  log "Deleting remote branches already merged to $current_branch..."
  while IFS= read -r branch; do
    branch=$(trim_string "$branch")
    [ -n "$branch" ] || continue
    remote=${branch%%/*}
    branch_name=${branch#*/}
    [ "$branch_name" != "$current_branch" ] || continue
    if [ "$branch_name" = "HEAD" ]; then
      continue
    fi
    if test -n "$filter" && ! printf '%s' "$branch_name" | grep -E "$filter" >/dev/null; then
      continue
    fi
    if test "$branch_name" = "master" || test "$branch_name" = "main"; then
      continue
    fi
    if $dry_run; then
      log "[DRYRUN]: git push --delete $remote $branch_name"
    else
      git push --delete "$remote" "$branch_name"
    fi
  done < <(git for-each-ref --merged="$current_branch" --format='%(refname:short)' refs/remotes)
fi
