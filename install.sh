#!/usr/bin/env bash

shouldAct=true
force=false
symlinks=false
while getopts ":nfs" opt; do
  case $opt in
    n)
      echo "-n provided. DRY RUN"
      shouldAct=false
      ;;
    f)
      force=true
      ;;
    s)
      symlinks=true
      ;;
    \?)
      echo "Invalid option $opt" >&2
      ;;
  esac
done
shift $((OPTIND - 1))

srcFolder=${1:?"Must provide source folder"}
srcFolder=$(cd "$srcFolder" 2>/dev/null && pwd -P) || {
  echo "Source folder does not exist: $1" >&2
  exit 1
}

while IFS= read -r -d $'\0' leaf; do
  file=${leaf#"$srcFolder"/}
  srcFile=$leaf
  targetFile="$HOME/$file"
  # Check for existing file
  if [ -f "$targetFile" ]; then
    if $force; then
      echo "Removing existing file: $targetFile"
      if $shouldAct; then
        rm "$targetFile"
      fi
    else
      echo "File exists. Skipping: $targetFile"
      continue
    fi
  fi
  # Check for existing (broken) link
  if [ -L "$targetFile" ]; then
    if $force; then
      echo "Removing existing link: $targetFile"
      if $shouldAct; then
        rm "$targetFile"
      fi
    else
      echo "Link exists. Skipping: $targetFile"
      continue
    fi
  fi
  if $symlinks; then
    message="Creating symlink"
  else
    message="Copying file"
  fi
  echo "$message: $targetFile -> $srcFile"
  if $shouldAct; then
    mkdir -p "$(dirname "$targetFile")"
    if $symlinks; then
      ln -s "$srcFile" "$targetFile"
    else
      cp "$srcFile" "$targetFile"
    fi
  fi
done < <(find -L "$srcFolder" -type f -print0)
