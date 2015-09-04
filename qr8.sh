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

function writeTags() {

	for tag in ${tags[@]}
	do	
		touch "tag.$tag"
	done
}

function findRoot() {
	local directory=$PWD
	while [[ -d "$directory" ]] 
	do
		if [[ -e "${directory}/.qr8" ]]
		then 
			echo $directory	
			
			break
		fi
			
		directory=${directory#/*}	
	done
}

#get non-tag parameters
for argument in "${args[@]}"
do
	echo argument:  $argument
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
	#If option i or init create .qr8 file
	elif [[ $argument =~ ^--i(nit)? ]]
	then
		touch .qr8
		mkdir .trash
		return
	#If option p or pop move top directory to trash and go into it
	elif [[ $argument =~ ^--p(op)? ]]
	then
		return	
	#If option t or top find top directory and go into it
	elif [[ $argument =~ ^--t(op)? ]]
	then
		return
	elif [[ $argument =~ ^https?://  ]] 
    #check if url
	then
		link=$argument
	elif [[ -z $description ]]
	then
		description="$argument"
	else
		tags+=($argument)
	fi
done

expirationDate=`date '+%y%m%d' -d "+$dayCount days"`

note=${PWD##*/}
echo note: $note
# Check if in note directory
if [[  $note =~ ^[0-9]{6}\.|- ]]
then 
	cd ..
	newNote="${expirationDate}.${note#*[-\.]}"
	mv "$note" "$newNote"
	cd "$newNote"
	writeTags
else
	root=$(findRoot)
	if [[ ! -z $root ]]
	then
		newNote="${root}/${expirationDate}.${description}"
		mkdir "$newNote"
		cd "$newNote"
		writeTags
	else
		echo No QR8 root found.
	fi
fi

