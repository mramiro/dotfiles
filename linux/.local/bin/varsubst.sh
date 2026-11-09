#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
  echo "Usage: ${0##*/} <template-file> <variables-file>" >&2
  exit 2
fi

sub_file=$1
vars_file=$2

if [ ! -r "$sub_file" ]; then
  echo "Template file is not readable: $sub_file" >&2
  exit 1
fi
if [ ! -r "$vars_file" ]; then
  echo "Variables file is not readable: $vars_file" >&2
  exit 1
fi
if ! command -v envsubst >/dev/null 2>&1; then
  echo "Required command 'envsubst' was not found in PATH. On macOS, install GNU gettext (for example: brew install gettext)." >&2
  exit 127
fi

var_list=''
while IFS= read -r var || [ -n "$var" ]; do
  case $var in
    '' | \#*)
      continue
      ;;
  esac

  case $var in
    *=*)
      name=${var%%=*}
      ;;
    *)
      echo "Invalid variable assignment in $vars_file: $var" >&2
      exit 1
      ;;
  esac

  if ! [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Invalid variable name in $vars_file: $name" >&2
    exit 1
  fi

  export "$var"
  var_list="$var_list\$$name "
done < "$vars_file"

envsubst "$var_list" < "$sub_file"
