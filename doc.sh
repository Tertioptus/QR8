#!/bin/bash

args=("$@")

NAME=$1 #Name should be the first parameter
EXPIRE="1m" #default expire to one month

#get non-tag parameters
while true; do

    #check if expire time
	if [[ $args[i] =~ ^([0-9][dwmy])+ ]] 
	then
		echo ${args[i]}
	fi

    #check if url
	if [[ $args[i] =~ ^https?://  ]] 
	then
		echo ${args[i]}
	fi

     #else get name
done

#get tags
