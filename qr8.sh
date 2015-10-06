#!/bin/bash
#
# qr8 [expiration]? [url]? [options]* [description] [tag]*
#
#########################################################################
args=("$@")
description=""
tags=()
NAME=$1 #Name should be the first parameter
dayCount=1 #default expire to one week
expirationDate=

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
		if [[ -e "${directory}/$1" ]]
		then 
			echo $directory	
			
			break
		fi
			
		directory=${directory%/*}	
	done
}

function findQr8Root() {
	findRoot ".qr8"
}

function findQNoteRoot() {
	findRoot "qnote"
}

root=$(findQr8Root)

function getTop() {
	echo $(ls "$root" | head -1)
}

function show() {
	title=`basename "$PWD"`
	echo -e "\e[32m$title:\e[0m"
	ls | head -20
	listCount=`ls -1 | wc -l`
	if [[ listCount -gt 2 ]]
	then
		echo '...'
	fi
}

#If no arguments "qr8" alone means go to root
if [[ -z ${args[@]} ]]
then 
	cd "$root"
else 
	#get non-tag parameters
	for argument in "${args[@]}"
	do
		#check if expire time
		if [[ $argument =~ ^([0-9]+[dwmy])+ ]] 
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
		#If expire time is date format
		elif [[ $argument =~ ^[0-9]{6} ]]
		then
			expirationDate=$argument
		#If option i or init create .qr8 file
		elif [[ $argument =~ ^--i(nit)? ]]
		then
			touch .qr8
			mkdir .trash
			show
			return
		#If option d or drop move current directory to trash and go into it
		elif [[ $argument =~ ^--d(rop)? ]]
		then
			current="$(findQNoteRoot)"
			echo current: $current
			cd "$root"
			mv "$current" "$root/.trash/"
			show
			return	
		#If option p or pop move top directory to trash and go into it
		elif [[ $argument =~ ^--p(op)? ]]
		then
			top=$(getTop)
			poppedTop="$root/.trash/$top"
			mv "$root/$top" "$poppedTop"
			cd "$poppedTop"
			echo -e "\e[31m(In trash!)\e[0m"
			show
			newTop=$(getTop)
			echo -e "\e[34;47mNew top: $newTop\e[0m"
			return	
		#If option t or top find top directory and go into it
		elif [[ $argument =~ ^--t(op)? ]]
		then
			top=$(getTop)
			cd "$root/$top"
			show
			return
		#If option p or pop move top directory to trash and go into it
		elif [[ $argument =~ ^--c(op)? ]]
		then
			hash="#`echo -n $PWD | openssl dgst -md5 -binary | openssl enc -base64 | sed 's#/##g'`"
			touch $hash
			qr8 1d `basename $PWD` $hash
			return	
		elif [[ $argument =~ ^--h(op)? ]]
		then
			#get hash jump to hash
			hash=(`printf '%s\n' \#*`)

			#search for hash from root
			HOP_DIR=(`find $ROOT -maxdepth 1 -name $hash`}

			#go to first
			cd $HOP_DIR
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

	if [[ -z $expirationDate ]]
	then
		expirationDate=`date '+%y%m%d' -d "+$dayCount days"`
	fi

	note=${PWD##*/}
	# Check if in note directory
	if [[  $note =~ ^[0-9]{6}\.|- ]]
	then 
		cd ..
		newNote="${expirationDate}.${note#*[-\.]}"
		mv "$note" "$root/$newNote"
		cd "$root/$newNote"
		touch qnote
		writeTags
	else
		if [[ ! -z $root ]]
		then
			newNote="${root}/${expirationDate}.${description}"
			mkdir "$newNote"
			cd "$newNote"
			touch qnote
			writeTags
		else
			echo No QR8 root found.
		fi
	fi
fi

show
