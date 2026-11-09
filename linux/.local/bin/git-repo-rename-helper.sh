#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

self=${0##*/}

function usage {
  cat << EOF
    Analyzes one or more git repositories looking for any unreachable remotes. For each bad remote detected, prompts the user to provide a replacement URL.

    Usage: $self [option...]

    Options:

      -p <path> The path to the git repository to analyze. If the -r option is provided, this should be a directory containing git repositories.
                 Defaults to the current directory.
      -r         Recursively analyze all git repositories found within the provided path (up to one level of depth).
      -f         Prompt for remote URL replacement without checking for issues first.
      -m         After replacing any remote URL in a repository, also attempt to rename the folder that contains it, prompting with a suggestion based on the new URL.
                 The URL is taken from either the 'origin' remote (if it exists) or the first one that 'git remote' returns after all replacements are made.
      -n         Perform a trial run without making any change.
      -h         Display this help message.

    Examples:

      # Analyze the git repository in the current directory, prompting for a replacement URL on each unreachable remote.
      $self

      # Sames as above, but just print the changes that would be made without actually making them.
      $self -n

      # Find all folders containing repositories within a directory and prompt for a replacement URL on each of their remotes,
      # regardless of the remote status. Also attempt to rename each folder found.
      $self -r -p /path/to/repositories -f -m
EOF
}

function parse_args {
  OPTIND=1
  while getopts ":p:rfmnh" option; do
    case $option in
      p)
        TARGET_DIR=$OPTARG
        ;;
      r)
        RECURSE=true
        ;;
      f)
        FORCE=true
        ;;
      m)
        MOVE_FOLDER=true
        ;;
      n)
        DRY_RUN=true
        ;;
      h)
        usage
        exit 0
        ;;
      :)
        echo "Option '-$OPTARG' requires an argument." >&2
        exit 2
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 2
        ;;
    esac
  done
  shift $((OPTIND - 1))
  if [ $# -gt 0 ]; then
    echo "Unexpected argument: $1" >&2
    exit 2
  fi
}

function handle_url_replacement {
  local repo_root=$1
  local remote_name=$2
  local remote_url=$3
  local entered_url
  local new_url
  printf "Enter new URL for remote '%s' [%s]: " "$remote_name" "$remote_url"
  IFS= read -r -e entered_url
  new_url=$(printf '%s' "$entered_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  new_url=${new_url:-$remote_url}
  if [ "$new_url" = "$remote_url" ]; then
    echo "No URL change entered. Skipping."
    return 1
  fi
  if $DRY_RUN; then
    echo "[DRYRUN] Would replace remote URL with '$new_url'."
  else
    git -C "$repo_root" remote set-url "$remote_name" "$new_url"
    echo "Remote '$remote_name' URL replaced with '$new_url'."
  fi
  return 0
}

function handle_folder_rename {
  local repo_root
  repo_root=$(cd "$1" 2>/dev/null && pwd -P) || {
    echo "Cannot resolve repository path: $1" >&2
    return 1
  }
  local suggested_name=$2
  local entered_repo_name
  local new_repo_name
  local new_repo_path
  printf "Enter new folder name for this repository [%s]: " "$suggested_name"
  IFS= read -r -e entered_repo_name
  new_repo_name=$(printf '%s' "$entered_repo_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  new_repo_name=${new_repo_name:-$suggested_name}
  new_repo_name=${new_repo_name##*/}
  if [ -z "$new_repo_name" ] || [ "$new_repo_name" = "." ] || [ "$new_repo_name" = ".." ]; then
    echo "Invalid repository folder name. Skipping."
    return 0
  fi
  new_repo_path=$(dirname "$repo_root")/$new_repo_name
  if [ "$new_repo_path" = "$repo_root" ]; then
    echo "Repository folder name is unchanged. Skipping."
    return 0
  fi
  if $DRY_RUN; then
    echo "[DRYRUN] Would rename repository folder to '$new_repo_path'."
    return 0
  fi
  if [ -e "$new_repo_path" ]; then
    echo "Cannot rename repository: destination already exists: $new_repo_path" >&2
    return 1
  fi
  if [ "$repo_root" = "$(pwd -P)" ]; then
    cd ..
  fi
  mv "$repo_root" "$new_repo_path"
  echo "Repository folder renamed to '$new_repo_path'."
}

function process_remote {
  local repo_root=$1
  local remote_name=$2
  local remote_url
  echo "Analyzing remote '$remote_name'"
  remote_url=$(git -C "$repo_root" remote get-url "$remote_name")
  if $FORCE; then
    echo "Forcing replacement prompt."
    handle_url_replacement "$repo_root" "$remote_name" "$remote_url"
  else
    echo "Attempting to fetch remote info from: '$remote_url'..."
    if git -C "$repo_root" remote show "$remote_name" >/dev/null 2>&1; then
      echo "Remote '$remote_name' information fetched successfully. No change necessary. Use -f to force replacement without checking."
      return 1
    else
      echo "Failed to fetch remote information for remote '$remote_name'. Attempting to replace URL."
      handle_url_replacement "$repo_root" "$remote_name" "$remote_url"
    fi
  fi
}

function process_repo {
  local repo_root=$1
  local remote
  echo "Analyzing repository at $repo_root"
  local remotes
  local counter=0
  local remote_name
  local remote_url
  remotes=$(git -C "$repo_root" remote)
  while IFS= read -r remote <&3; do
    [ -n "$remote" ] || continue
    if process_remote "$repo_root" "$remote"; then
      counter=$((counter + 1))
    fi
  done 3< <(printf '%s\n' "$remotes")
  if [ "$counter" -eq 0 ]; then
    echo "No remote URL replacements were made."
  else
    echo "Performed $counter remote URL replacements in repository '$repo_root'."
    if $MOVE_FOLDER && ! $DRY_RUN; then
      remote_name=origin
      if git -C "$repo_root" remote get-url "$remote_name" >/dev/null 2>&1; then
        echo "Using 'origin' remote as the base for the new folder name."
      else
        remote_name=$(printf '%s\n' "$remotes" | sed -n '1p')
        echo "Using the first remote found ('$remote_name') as the base for the new folder name."
      fi
      remote_url=$(git -C "$repo_root" remote get-url "$remote_name")
      remote_url=${remote_url%/}
      remote_url=${remote_url%.git}
      handle_folder_rename "$repo_root" "${remote_url##*/}"
    elif $MOVE_FOLDER; then
      echo "[DRYRUN] Skipping folder rename because the remote URL was not changed."
    fi
  fi
}

MOVE_FOLDER=false
RECURSE=false
FORCE=false
DRY_RUN=false
TARGET_DIR="."

parse_args "$@"

provided_path=$TARGET_DIR
if [ ! -d "$provided_path" ]; then
  echo "Directory '$provided_path' does not exist." 1>&2
  exit 1
fi

path=$(cd "$provided_path" && pwd -P)

if $DRY_RUN; then
  echo "[DRYRUN] Dry run enabled. No persistent changes will be made."
fi
if $RECURSE; then
  echo "Recursive mode enabled. Analyzing repositories in '$path' and its immediate subdirectories."
  if [ -d "$path/.git" ]; then
    process_repo "$path"
  fi
  for candidate in "$path"/* "$path"/.[!.]* "$path"/..?*; do
    [ -d "$candidate" ] || continue
    [ -d "$candidate/.git" ] || continue
    process_repo "$candidate"
  done
else
  if [ ! -d "$path/.git" ]; then
    echo "Directory '$path' is not a git repository. Use -r to enable recurse mode." 1>&2
    exit 1
  fi
  process_repo "$path"
fi
