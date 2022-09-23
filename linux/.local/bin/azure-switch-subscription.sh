#!/bin/bash

json=$(az account list)
if [ $? -eq 1 ] ; then
  az login
  json=$(az account list)
fi
echo "Select subscription from list:"
echo $json | jq -r '.[].name' | nl -w2 -s ') ' -
read -n1 opt && echo
IFS=$'\n' ids=($(echo $json | jq -r '.[].id'))
az account set --subscription "${ids[$((opt-1))]}" && az account show
