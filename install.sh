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
  shift $((OPTIND-1))
done

srcFolder=${1:?"Must provide source folder"}
# Remove trailing slash if present
srcFolder=$(basename "$srcFolder")

while IFS= read -r -d $'\0' leaf; do
  file=$(echo $leaf | sed "s#^$srcFolder/##")
  srcFile=$(realpath $leaf)
  targetFile="$HOME/"$(echo $leaf | sed "s#^$srcFolder/##")
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
  if [ -h "$targetFile" ]; then
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
  message=$($symlinks && echo "Creating symlink" || echo "Copying file")
  echo "$message: $targetFile -> $srcFile"
  if $shouldAct; then
    mkdir -p $(dirname "$targetFile")
    if $symlinks; then
      ln -s "$srcFile" "$targetFile"
    else
      cp "$srcFile" "$targetFile"
    fi
  fi
done < <(find -L $srcFolder -type f -print0)
