#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

self=$(echo $0 | sed 's|.*/||')

function usage {
  readarray message << EOF
    Analyzes one or more git repositories looking for any unreachable remotes. For each bad remote detected, prompts the user to provide a replacement URL.

    Usage: $self [option...]

    Options:

      -p, --path <path> The path to the git repository to analyze. If the -r option is provided, this should be a directory containing git repositories.
                        Defaults to the current directory.
      -r, --recurse     Recursively analyze all git repositories found within the provided path (up to one level of depth).
      -f, --force       Prompt for remote URL replacement without checking for issues first.
      -m, --rename      After replacing any remote URL in a repository, also atttempt to rename the folder that contains it, prompting with a suggestion based on the new URL.
                        The URL is taken from the either the 'origin' remote (if it exists) or the first one that 'git remote' returns after all replacements are made.
      -n, --dry-run     Perform a trial run without making any change.
      -h, --help        Display this help message.

    Examples:

      # Analyze the git repository in the current directory, prompting for a replacement URL on each unreachable remote.
      $self

      # Sames as above, but just print the changes that would be made without actually making them.
      $self -n

      # Find all folders containing repositories within a directory and prompt for a replacement URL on each of their remotes,
      # regardless of the remote status. Also attempt to rename each folder found.
      $self -r -p /path/to/repositories -f -m
EOF
  printf '%s' "${message[@]#    }"
}

function parse_args {
  local args=$(getopt -o "p:rfmnh" -l "path:,recurse,force,rename,dry-run,help" -- "$@") || exit 1
  eval "set -- $args"
  while true; do
    case $1 in
      -p | --path)
        TARGET_DIR=$2
        shift 2 ;;
      -r | --recurse)
        RECURSE=true
        shift ;;
      -f | --force)
        FORCE=true
        shift ;;
      -m | --rename)
        MOVE_FOLDER=true
        shift ;;
      -n | --dry-run)
        DRY_RUN=true
        shift ;;
      -h | --help)
        usage
        exit 0 ;;
      --)
        shift
        break ;;
      *)
        exit 1
    esac
  done
}

function handle_url_replacement {
  local repo_root=$1
  local remote_name=$2
  local remote_url=$3
  read -p "Enter new URL for remote '$remote_name': " -e -i "$remote_url" entered_url
  local new_url=$(echo $entered_url | xargs)
  if [ -z $new_url ]; then
    echo "No URL entered. Skipping."
    return 1
  fi
  if $DRY_RUN; then
    echo "[DRYRUN] Skipping remote URL replacement to '$new_url'."
  else
    git -C $repo_root remote set-url $remote_name $new_url
    echo "Remote '$remote_name' URL replaced with '$new_url'."
  fi
  return 0
}

function handle_folder_rename {
  local repo_root=$(realpath $1)
  local suggested_name=$2
  read -p "Enter new folder name for this repository: " -e -i "$suggested_name" entered_repo_name
  local new_repo_name=$(echo $entered_repo_name | xargs)
  local new_repo_path=$(dirname $repo_root)/$new_repo_name
  if [ -z $new_repo_name ] || [ "$new_repo_path" = "$repo_root" ]; then
    echo "No new repository name entered. Skipping."
    return 0
  fi
  if $DRY_RUN; then
    echo "[DRYRUN] Skipping folder rename to '$new_repo_path'."
    return 0
  fi
  if [ "$repo_root" = "$(pwd)" ]; then
    cd ..
  fi
  mv $repo_root $new_repo_path
  echo "Repository folder renamed to '$new_repo_path'."
}

function process_remote {
  local repo_root=$1
  local remote_name=$2
  echo "Analyzing remote '$remote_name'"
  local remote_url=$(git -C $repo_root remote get-url $remote_name)
  if $FORCE; then
    echo "Forcing replacement prompt."
    handle_url_replacement $repo_root $remote_name $remote_url
  else
    echo "Attempting to fetch remote info from: '$remote_url'..."
    if (git -C $repo_root remote show $remote_name &>/dev/null); then
      echo "Remote '$remote_name' information fetched successfully. No change necessary. Use -f to force replacement without checking."
      return 1
    else
      echo "Failed to fetch remote information for remote '$remote_name'. Attempting to replace URL."
      handle_url_replacement $repo_root $remote_name $remote_url
    fi
  fi
}

function process_repo {
  local repo_root=$1
  echo "Analyzing repository at $repo_root"
  local remotes=$(git -C $repo_root remote)
  declare -i counter=0
  for remote in $remotes; do
    if process_remote $repo_root $remote; then
      counter=$counter+1
    fi
  done
  if [ $counter -eq 0 ]; then
    echo "No remote URL replacements were made."
  else
    echo "Performed $counter remote URL replacements in repository '$repo_root'."
    if $MOVE_FOLDER; then
      local remote_name=origin
      if git -C $repo_root remote get-url $remote_name &>/dev/null; then
        echo "Using 'origin' remote as the base for the new folder name."
      else
        remote_name=$(echo $remotes | head -n 1)
        echo "Using the first remote found ('$remote_name') as the base for the new folder name."
      fi
      local remote_url=$(git -C $repo_root remote get-url $remote_name)
      handle_folder_rename $repo_root $(basename $remote_url)
    fi
  fi
}

MOVE_FOLDER=false
RECURSE=false
FORCE=false
DRY_RUN=false
TARGET_DIR="."

parse_args $@

provided_path=$TARGET_DIR
if [ ! -d $provided_path ]; then
  echo "Directory '$provided_path' does not exist." 1>&2
  exit 1
fi

path=$(realpath $provided_path)

$DRY_RUN && echo "[DRYRUN] Dry run enabled. No persistent changes will be made."
if $RECURSE; then
  echo "Recursive mode enabled. Analyzing all git repositories within the provided path."
  for repo in $(find $path -maxdepth 2 -type d -name .git); do
    process_repo $(dirname $repo)
  done
else
  if [ ! -d $path/.git ]; then
    echo "Directory '$path' is not a git repository. Use -r to enable recurse mode." 1>&2
    exit 1
  fi
  process_repo $path
fi
