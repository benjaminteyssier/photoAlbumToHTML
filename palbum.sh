#!/bin/bash

Help(){
   cat README.md
}

CheckInputDirectory(){
	if [[ ! -d $inputDirectory ]]
		then
			echo "Directory "$inputDirectory" DOES NOT exists."
			return
	fi
	numberOfImages=$(ls "$inputDirectory" -a | grep ".png\|.jpg" | wc -l)
	if [[ $numberOfImages -eq 0 ]]
		then
			echo "There is no image files in "$inputDirectory"."
			return
	fi
}

inputDirectory="$1"
outputDirectory="$2"

CheckInputDirectory

if [[ ! -d "$outputDirectory" ]]
	then 
		mkdir "$outputDirectory"
		touch "$outputDirectory"/index.html
fi