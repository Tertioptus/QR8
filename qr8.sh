#!/bin/bash
#
# qr8 [expiration]? [url]? [description] [tag]*
#
#########################################################################
args=("$@")
description=""
tags=()
NAME=$1 #Name should be the first parameter
dayCount=7 #default expire to one week

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
		done
    #check if url
	elif [[ $argument =~ ^https?://  ]] 
	then
		link=$argument
	elif [[ -e $description ]]
	then
		description=$argument
	elif
		tag+=($argument)
	fi
done

expirationDate=`date '+%y%m%d' -d "+$dayCount days"`

note=${PWD##*/}
# Check if in note directory
if [[  $note =~ ^[0-9]{6}\. ]]
then 
	cd ..
	newNote=${expirationDate}.${note%.}
	mv $note $newNote
	cd $newNote
else
	mkdir ${expirationDate}.${description}
fi

