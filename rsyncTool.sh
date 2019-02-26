#!/bin/bash

###################################################################
#Script Name	: rsyncTool.sh
#Description	: rsync two dirs and verify the content
#Author       : Yvan Uhlmann
#Email        : yvan.common@gmail.com
###################################################################


#~~~~~~~~~~~~~~~~~~THIS PART IS TO CHECK OS
makeOSCheck () {

  case "$OSTYPE" in
    darwin*)  makeRootCheck ;;
    linux*)   printf "Hello Linux\n" ;;
    *)        echo "unknown: $OSTYPE" ;;
  esac
}

#~~~~~~~~~~~~~~~~~~THIS PART IS FOR ROOTCHECK ON OSX
makeRootCheck () {

  # Check if root and re-execute if not
  if [ $(id -u) != "0" ]
  then
      sudo bash "$0" "$@"
      exit $?
  fi

}


#~~~~~~~~~~~~~~~~~~THIS PART IS FOR USER INPUT VARIABLES
askUserInputs () {

  #Welcome message
  printf "\n\e[1m==========  rsyncTool  ==========\e[0m\n"

  #Ask for Source_HomePath
  printf "\nDrag'n'drop Home dir from source: \n"
  read input
  #Del "'" prefix and suffix
  Source_HomePath="${input%\'}"
  Source_HomePath="${Source_HomePath#\'}"
  #Assign Source_HomeName
  Source_HomeName=$(echo "$Source_HomePath" | grep -Eo '\/[^\/]*$')

  #Ask for Destination_InterPath
  printf "Drag'n'drop dir of destination: \n"
  read input
  #Del "'" prefix and suffix
  Destination_InterPath="${input%\'}"
  Destination_InterPath="${Destination_InterPath#\'}"
  #Assign Destination_HomePath
  Destination_HomePath="$Destination_InterPath""$Source_HomeName"
}


#~~~~~~~~~~~~~~~~~~THIS PART IS FOR DIFFERENT LOG FILES

makeLogFiles () {

  #This is the number for the first prefix
  number=1
  #This is the first prefix
  prefix="$number"'-'

  #Test if the file with prefix n exists, keep going with n+1 if it does
  #Yes, only test fileProgress, so all three files have same number
  while test -e "$Destination_InterPath"/"$prefix"'rsyncProgress.txt'
  do
    #Increment number
    number=$((number+1))
    #Redifine prefix with new number
    prefix="$number"'-'
  done

  #If the helpdesker lacks common sense, mock him
  if [[ "$number" -ge 4 ]]
  then
    printf "\nLa définition de la folie, c’est de refaire toujours
    la même chose, et d’attendre des résultats différents.\n"
  fi

  #Once file does not exists, set the log files with final prefix
  fileProgress="$prefix"'rsyncProgress.txt'
  fileError="$prefix"'rsyncErrors.txt'
  fileVerification="$prefix"'rsyncVerification.txt'

}


#~~~~~~~~~~~~~~~~~~THIS PART IS FOR RSYNC

makeRsync () {

  #Print header
  printf '\nRsync in progress...\n'

  #This curly bracket will redirect rsync error to rsyncErrors.txt
  {

  #rsync update + redirection to file with tee + stdout timestamp
  rsync -ru --progress "$Source_HomePath" "$Destination_InterPath" |
  tee "$Destination_InterPath"/"$fileProgress" |
  while read line
  do
  	#for each stdout, print timestamp
  	DATE_WITH_TIME=`date "+%H:%M:%S, %d.%m.%Y"`
  	printf 'Last transfer at '"$DATE_WITH_TIME"'.'\\r
  done

} 2>"$Destination_InterPath"/"$fileError"

  #Print footer in terminal
  printf '\nRsync ended.\n'
}


#~~~~~~~~~~~~~~~~~~THIS PART IS FOR RSYNC VERIFICATION

makeVerification () {

  #Print header
  printf '\nVerifying rsync...\n'

  #This curly bracket will redirect all output from the script in a file
  #See it's counter part at the end of the script
  {

  #Let's make a loop to launch verification on both Source and Destination
  for i in 1 2
  do
    if [[ "$i" == 1 ]]
    then
      target="$Source_HomePath"
      label="Source"
    else
      target="$Destination_HomePath"
      label="Destination"
    fi

    #Let's start the verification with a nice header
    printf '\n~~~~~~~~~~~~'"$label"' Results~~~~~~~~~~~~\n\n'
    #Then check if dir exist
    if [ -d "$target" ]
    then
    	#Move to target
    	cd "$target"
    	#Set variables for later
    	total=0
      singleFileNum=0
    	#For every dir in input path, print number of files
    	for element in "$target"/*
    	do
    		#Check if target/* element is a dir
    		if [ -d "$element" ]
    		then
    			#Create file sum var
          fileNumSum=$(find "$element" -type f | wc -l)
          #Create var for clearer path
    			clearerPath=$(echo "$element" | grep -Eo '\/[^\/]*$')
          #Print the three variables
    			printf "$clearerPath"' : '"$fileNumSum"' files.\n'
    			#Increment total
    			total=$((total+fileNumSum))
    		#If it's a file
        else
          #Increment singleFileNumNum var
          singleFileNumSum=$((singleFileNum+1))
    		fi
    	done

      #Print singleFileNum total
      printf 'Single files in /home : '"$singleFileNum"' files.\n'
    	#Print total of both total and singleFileNum
    	printf '\nTotal is: '"$((total+singleFileNum))"' files.\n\n'
    else
    	#If dir does not exist, return error
    	printf '\n\n*******Error with '"$label"' Path*******\n\n'
    fi


  #End of Source/Destination loop
  done


  #This is the counter part of the earlier curly bracket to redirect output
} > "$Destination_InterPath"/"$fileVerification"

  #Print footer
  printf 'Rsync verification file created in:\n'"$Destination_InterPath"'\n'

  #Closing message
  printf "\n\e[1m=================================\e[0m\n\n\n"
}


#~~~~~~~~~~~~~~~~~~THIS IS THE PROGRAM

makeOSCheck
askUserInputs
makeLogFiles
makeRsync
makeVerification

# <3
