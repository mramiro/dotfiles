#!/usr/bin/env bash

act=true
force=false
symlinks=false
prefix=""
while getopts ":nfs" opt; do
  case $opt in
    n)
      act=false
      prefix="[NOOP] "
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
srcFolder=$(basename "$srcFolder")

while IFS= read -r -d $'\0' leaf; do
  file=$(echo $leaf | sed "s#^$srcFolder/##")
  srcFile=$(realpath $leaf)
  targetFile="$HOME/"$(echo $leaf | sed "s#^$srcFolder/##")
  if [ -f "$targetFile" ]; then
    if $force; then
      echo $prefix"Removing existing file: $targetFile"
      if $act; then
        rm "$targetFile"
      fi
    else
      echo $prefix"File exists. Skipping: $targetFile"
      continue
    fi
  fi
  message=$($symlinks && echo "Creating symlink" || echo "Copying file")
  echo "$prefix$message: $targetFile -> $srcFile"
  if $act; then
    mkdir -p $(dirname "$targetFile")
    if $symlink; then
      ln -s "$srcFile" "$targetFile"
    else
      cp "$srcFile" "$targetFile"
    fi
  fi
done < <(find $srcFolder -type f -print0)
