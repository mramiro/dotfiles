#!/usr/bin/env bash

set -o nounset
set -o pipefail

for command_name in az jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command '$command_name' was not found in PATH." >&2
    exit 127
  fi
done

json=$(az account list 2>/dev/null) || json=""
if [ -z "$json" ] || ! jq -e 'type == "array" and length > 0' >/dev/null 2>&1 <<<"$json"; then
  echo "No Azure subscriptions are cached. Signing in..."
  az login || exit $?
  json=$(az account list) || exit $?
fi

if ! jq -e 'type == "array" and length > 0' >/dev/null 2>&1 <<<"$json"; then
  echo "No Azure subscriptions are available to select." >&2
  exit 1
fi

IFS=$'\n' names=($(jq -r '.[].name' <<<"$json"))
IFS=$'\n' ids=($(jq -r '.[].id' <<<"$json"))

echo "Select subscription:"
for ((i = 0; i < ${#names[@]}; i++)); do
  printf "%2d) %s\n" "$((i + 1))" "${names[$i]}"
done

read -r -p "Selection: " opt
if ! [[ "$opt" =~ ^[0-9]+$ ]] || (( opt < 1 || opt > ${#ids[@]} )); then
  echo "Invalid selection: $opt" >&2
  exit 1
fi

az account set --subscription "${ids[$((opt - 1))]}" || exit $?
az account show
