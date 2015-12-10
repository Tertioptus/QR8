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
TRUE=0
FALSE=1
TODAY=`date '+%y%m%d'`
STARTED_IN_TRASH=false

if [[ $PWD =~ ".trash"  ]] 
then
	STARTED_IN_TRASH=true
fi

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

function isNote() {

	if [[ $note =~ ^[0-9]{6} ]]
	then
		return $TRUE
	else
		return $FALSE
	fi
}

function isPastDue() {
	if ! isNote $1; then
		return $FALSE
	fi

	noteDate=${1:0:6}
	if [[ $TODAY -gt $noteDate ]]
	then
		return $TRUE
	else
		return $FALSE
	fi
}

function isDue() {
	if ! isNote $1; then
		return $FALSE
	fi

	noteDate=${1:0:6}
	if [[ $TODAY -eq $noteDate ]]
	then
		return $TRUE
	else
		return $FALSE
	fi
}

function showNote() {
	note=$1	

	if isPastDue $note		
	then
		echo -e "\e[97;41m$note\e[0m"
	elif isDue $note
	then
		echo -e "\e[90;43m$note\e[0m"
	else
		echo $note
	fi
}

root=$(findQr8Root)

function getTop() {
	echo $(ls "$root" | head -1)
}

function showNoteSnippet() {
	if [[ -e qnote ]] && [[ -s qnote ]]
	then
		echo "\"`head -3 qnote`$(if [ $(cat qnote | wc -l) -gt 3 ]; then echo "..."; fi)\"" 
	fi
}

function show() {
	title=`basename "$PWD"`
	echo -e "\e[32m$(showNote $title):\e[0m"
	showNoteSnippet
	IFS=$'\t\n'
	notes=(`ls | head -20`)
	for note in ${notes[@]}
	do
		showNote $note
	done
	unset $IFS #or IFS=$' \t\n'
	listCount=`ls -1 | wc -l`
	if [[ listCount -gt 20 ]]
	then
		echo '...'
	fi
}

function getHash() {

	#TODO check for q# in directory first
	
	echo "q#`echo -n $PWD | openssl dgst -md5 -binary | openssl enc -base64 | sed 's#/##g'`"
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
		#If option s or stop go to note root of the system
		elif [[ $argument =~ ^--s(top)? ]]
		then
			current="$(findQNoteRoot)"
			cd "$current"
			return	
		#If option p or pop move top directory to trash and go into it
		elif [[ $argument =~ ^--p(op)? ]]
		then
			top=$(getTop)
			poppedTop="$root/.trash/$top"
			mv "$root/$top" "$poppedTop"
			cd "$poppedTop"
			echo -e "\e[47;31mIN TRASH!!!IN TRASH!!!IN TRASH!!!\e[0m"
			show
			echo -e "\e[47;31mIN TRASH!!!IN TRASH!!!IN TRASH!!!\e[0m"
			echo
			cd "$root"
			show
			cd "$poppedTop"
			return	
		#If option t or top find top directory and go into it
		elif [[ $argument =~ ^--t(op)?$ ]]
		then
			top=$(getTop)
			cd "$root/$top"
			show
			return
		#If option p or pop move top directory to trash and go into it
		elif [[ $argument =~ ^--c(op)? ]]
		then
			if `[ -a q#* ]` 
			then
				echo "Hash for this channel already exists."
			else
				hash=$(getHash)
				expirationDate=`date '+%y%m%d' -d "+$dayCount days"`
				note_title=`basename $PWD`
				copped_note=$root/$expirationDate.${note_title#*[-\.]}
				mkdir $copped_note
				touch $hash
				mv * $copped_note
				touch $hash
				cd $copped_note
				touch qnote
			fi
			return	
		elif [[ $argument =~ ^--h(op)? ]]
		then
			if `[ -a q#* ]` 
			then
				#get hash jump to hash
				hash=(`printf '%s\n' q\#*`)

				#search for hash from root
				HOP_DIRS=(`find $root -name $hash`)

				for DIR in ${HOP_DIRS[@]}
				do
					if [[ ! `dirname $DIR` =~ ${PWD#./}   ]]
					then
						#go to first
						cd "`dirname $DIR`"
						break	
					fi
				done
			else
				echo "No hash channel provided."
			fi
			return	
		elif [[ $argument =~ ^--trace ]]
		then
			traceOrigin=$PWD 
			
			while true 
			do
				if `[ -a q#* ]` 
				then
					qr8 --hop
					echo "* ${PWD#$root}"
				fi
				
				if `[ -a qnote* ]`
				then
					break
				else
					#if not qnote, repeat
					qr8 --stop
				fi
			done
			cd "$traceOrigin"
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
			touch ".$(getHash)"
			writeTags
		else
			echo No QR8 root found.
		fi
	fi
fi

#If note started in trash, display a visible banner when it is pushed out for verification
if [[ $STARTED_IN_TRASH ]]
then
	echo -e "\e[42;37mOUT OF TRASH!!!\e[0m\e[47;32mOUT OF TRASH!!!\e[0m\e[42;37mOUT OF TRASH!\e[0m"
fi
show
