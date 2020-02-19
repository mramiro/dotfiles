#!/bin/bash

sub_file=$1
vars_file=$2

var_list=''
for var in $(cat $vars_file); do
  readarray -d '=' -t split <<< "$var"
  var_list="$var_list"'$'"${split[0]},"
  export $var
done

envsubst $var_list < $sub_file
