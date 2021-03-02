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
  echo $1 | sed 's/^[[:space:]]*//g;s/[[:space:]]*$//g'
}

function exec_cmd() {
  cmd=${1:?"Missing argument: cmd"}
  dry_run=${2:-false}
  if test $dry_run = true; then
    log "[DRYRUN]: $cmd"
  else
    eval "$cmd"
  fi
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

current_branch=${1:-master}
# current_branch=$(git rev-parse --abbrev-ref HEAD)

log "Switching to branch: $current_branch"
git checkout $current_branch
echo "Deleting local branches already merged to $current_branch..."
branches=$(git branch --merged | sed "/$current_branch/d")
for branch in $branches; do
  exec_cmd "git branch -d $branch" $dry_run
done

if test $include_remotes = true; then
  log "Pulling latest changes into $current_branch"
  git pull
  log "Pruning stale branches in remotes..."
  for remote in $(git remote); do
    exec_cmd "git prune $remote" $dry_run
  done
  log "Deleting remote branches already merged to $current_branch..."
  branches=$(git branch --remotes --merged | sed "/origin\\/HEAD/d;/origin\\/$current_branch/d")
  for branch in $branches; do
    remote=$(trim_string $branch | cut -d / -f 1)
    branch_name=$(trim_string $branch | cut -d / -f 2-)
    if test -n "$filter" && ! echo $branch_name | grep -E "$filter" 1>/dev/null; then
      continue
    fi
    exec_cmd "git push --delete $remote $branch" $dry_run
  done
fi
