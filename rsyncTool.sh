#!/bin/bash

###################################################################
#Script Name	: rsyncTool.sh
#Version      : 2.0
#Date       	: May 2019
#Author       : Yvan Uhlmann
#Email        : yvan.uhlmann@gmail.com
###################################################################


#~~~~~~~~~~~~~~~~~~THIS PART IS TO CHECK OS
makeOSCheck () {

  case "$OSTYPE" in
    darwin*)  makeRootCheck ;;
    linux*)   printf "On Linux, copy/paste and launch rsyncTool.sh
              on the Desktop might resolve some errors.\n" ;;
    *)        printf "Unknown OS: $OSTYPE\n" ;;
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
  printf "\nDrag'n'drop Home dir from source (home dir in internal drive) : \n"
  read input
  #Del "'" prefix and suffix
  Source_HomePath="${input%\'}"
  Source_HomePath="${Source_HomePath#\'}"
  #Assign Source_HomeName
  Source_HomeName=$(echo "$Source_HomePath" | grep -Eo '\/[^\/]*$' | tr -d '/')

  #Ask for Destination_InterPath
  printf "Drag'n'drop dir of destination (inter dir in Helpdisk) : \n"
  read input
  #Del "'" prefix and suffix
  Destination_InterPath="${input%\'}"
  Destination_InterPath="${Destination_InterPath#\'}"
  #Assign Destination_HomePath
  Destination_HomePath="$Destination_InterPath"'/'"$Source_HomeName"
}


#~~~~~~~~~~~~~~~~~~THIS PART IS FOR DIFFERENT LOG FILES

makeLogFiles () {

  #This is the number for the first prefix
  number=1
  #This is the first prefix
  prefix="$number"'-'"$Source_HomeName"'-'

  #Test if the file with prefix n exists, keep going with n+1 if it does
  #Only test rsyncProgress.txt, so all three files have same number
  while test -e "$Destination_InterPath"/"$prefix"'rsyncProgress.txt'
  do
    #Increment number
    number=$((number+1))
    #Redefine prefix with new number
    prefix="$number"'-'"$Source_HomeName"'-'
  done

  #If the helpdesker lacks common sense, mock him
  if [ "$number" -ge 4 ]
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

  #This curly bracket will redirect rsync errors to rsyncErrors.txt
  #As tested, each file and each line print is a RTA (real-time application),
  # ie. it is not "only printed after process is finished"
  {

  #rsync update + redirection to file with tee + stdout timestamp
  firstline=true
  rsync -rul --progress "$Source_HomePath" "$Destination_InterPath" |
  tee "$Destination_InterPath"/"$fileProgress" |
  while read line
  do
    if [ "$firstline" = true ]
    then
      printf 'Building file list...'\\r
      firstline=false
    else
      DATE_WITH_TIME=`date "+%H:%M:%S, %d.%m.%Y"`
    	printf 'Last transfer at '"$DATE_WITH_TIME"'.'\\r
    fi
  done

  #This is the counter part of the earlier curly bracket to redirect output
  } 2>"$Destination_InterPath"/"$fileError"

  #Print footer in terminal
  if [ -s "$Destination_InterPath"/"$fileError" ]
  then
    printf '\nRsync ended with errors.\nSee '"$fileError"' for more infos.\n'
  else
    printf '\nRsync ended without any errors.\n'
  fi
}


#~~~~~~~~~~~~~~~~~~THIS PART IS FOR RSYNC VERIFICATION

makeVerification () {

  #Print header
  printf '\nVerifying rsync...\n'

  #This curly bracket will redirect all output from the script in a file
  #See it's counter part at the end of the script
  {

  #First, verify that we have access to both source and destination
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

    #Set var for rsyncVerification.txt
    tempSymlinks=0
    tempShortcuts=0
    tempAlias=0
    tempFiles=0
    totalSymlinks=0
    totalShortcuts=0
    totalAlias=0
    totalFiles=0
    singleSymlinks=0
    singleShortcuts=0
    singleAlias=0
    singleFiles=0
    total=0

    #Prevent line break at spaces
    IFS=$'\n'

    #list every element in Source_HomePath
    for E in `find "$target" -mindepth 1 -maxdepth 1 | sort -f`; do

      #Start rules for dirs
      if [ -d "$E" ]; then

        #Inside dir "E", print file types per line (ignore max details)
        #Alias and Shortcuts are in 'type f', when symlinks are in 'type l'
        for L in `find "$E" \( -type l -o -type f \) | tr '\n' '\0' | xargs \
        -0 -n1 file -h -b -e ascii -e apptype -e encoding -e tokens -e cdf \
        -e compress -e elf -e tar`; do
          #Count type per line: alias or shortcut or symLink or else
          if grep -iq "MacOS Alias file" <<<"$L"; then
            tempAlias=$((tempAlias+1))
          elif grep -iq "symbolic link" <<<"$L"; then
            tempSymlinks=$((tempSymlinks+1))
          elif grep -iq "MS Windows shortcut" <<<"$L"; then
            tempShortcuts=$((tempShortcuts+1))
          else
            tempFiles=$((tempFiles+1))
          fi
        done

        #Print results for dir "E"
        clearerPath=$(echo "$E" | grep -Eo '\/[^\/]*$')
        printf "$Source_HomeName""$clearerPath"' : '"$tempFiles"' files.\n'
        if [ "$tempAlias" != 0 ]; then
          printf '__Aliases : '"$tempAlias"'.\n'
        fi
        if [ "$tempSymlinks" != 0 ]; then
          printf '__SymLinks : '"$tempSymlinks"'.\n'
        fi
        if [ "$tempShortcuts" != 0 ]; then
          printf '__Shortcuts : '"$tempShortcuts"'.\n'
        fi

        #Increment totals
        totalFiles=$((totalFiles+tempFiles))
        totalAlias=$((totalAlias+tempAlias))
        totalSymlinks=$((totalSymlinks+tempSymlinks))
        totalShortcuts=$((totalShortcuts+tempShortcuts))

        #Reset variables for next loop on files per line
        tempFiles=0
        tempAlias=0
        tempSymlinks=0
        tempShortcuts=0

      #End of the rules on a dir "E"
      fi

      #Start rules for files "E"
      if [ -f "$E" ]; then

        #Set var like before
        L=$(file -h "$E")
        #Increment type per file
        if grep -iq "MacOS Alias file" <<<"$L"; then
          singleAlias=$((singleAlias+1))
        elif grep -iq "symbolic link" <<<"$L"; then
          singleSymlinks=$((singleSymlinks+1))
        elif grep -iq "MS Windows shortcut" <<<"$L"; then
          singleShortcuts=$((singleShortcuts+1))
        else
          singleFiles=$((singleFiles+1))
        fi

      #End of rule for files "E"
      fi

    #End of the elements "E" loop
    done

    #Now print all single files
    printf "$Source_HomeName"'/ : '"$singleFiles"' files.\n'
    if [ "$singleAlias" != 0 ]; then
      printf '__Aliases : '"$singleAlias"'.\n'
    elif [ "$singleSymlinks" != 0 ]; then
      printf '__SymLinks : '"$singleSymlinks"'.\n'
    elif [ "$singleShortcuts" != 0 ]; then
      printf '__Shortcuts : '"$singleShortcuts"'.\n'
    fi

    #Calculate totals
    totalFiles=$((totalFiles+singleFiles))
    totalAlias=$((totalAlias+singleAlias))
    totalSymlinks=$((totalSymlinks+singleSymlinks))
    totalShortcuts=$((totalShortcuts+singleShortcuts))

    #Now print total
    printf '\nTotal files in '"$Source_HomeName"'/ : '"$totalFiles"' files.\n'
    if [ "$totalAlias" != 0 ]; then
      printf '__Aliases : '"$totalAlias"'.\n'
    fi
    if [ "$totalSymlinks" != 0 ]; then
      printf '__SymLinks : '"$totalSymlinks"'.\n'
    fi
    if [ "$totalShortcuts" != 0 ]; then
      printf '__Shortcuts : '"$totalShortcuts"'.\n'
    fi

  done

  #Print footer message
  printf '\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n
  Si les totaux ne correspondent pas,
  consultez rsyncErrors.txt\n'

  #This is the counter part of the earlier curly bracket to redirect output
  } > "$Destination_InterPath"/"$fileVerification"

  #Print footer
  printf 'Rsync verification file created in:\n'"$Destination_InterPath"'\n'

  #Closing message/End of program
  printf "\n\e[1m=================================\e[0m\n\n\n"
}


#~~~~~~~~~~~~~~~~~~THIS IS THE PROGRAM

makeOSCheck
askUserInputs
makeLogFiles
makeRsync
makeVerification

# <3
