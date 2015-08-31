#!/bin/bash

args=("$@")

NAME=$1 #Name should be the first parameter
EXPIRE="1m" #default expire to one month

#get non-tag parameters
for argument in ${args[@]}
do
    #check if expire time
	if [[ $argument =~ ^([0-9][dwmy])+ ]] 
	then
		dayCount=0
		notices=(`sed 's/[wdmy]/&\n/g' <<< "$argument"`)
		for notice in ${notices[@]}
		do
			case "${notice:1}" in
			
			d) days=1
				;;

			w) days=7
				;;

			m) days=31
				;;
	
			y) days=365
				;;
		
			esac
			dayCount=$(($dayCount+${notice:0:1}*$days))
			echo day count: $dayCount
		done
		echo ${#notices[@]}
		expirationDate=`date '+%y%m%d' -d "+$dayCount days"`
		echo $expirationDate
	fi

    #check if url
	if [[ $argument =~ ^https?://  ]] 
	then
		echo ${args[i]}
	fi

     #else get name
done

#get tags
