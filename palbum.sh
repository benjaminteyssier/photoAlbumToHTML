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
	numberOfImages=$(ls "$inputDirectory" -a | grep ".png\|.PNG\|.jpg\|.JPG" | wc -l)
	if [[ $numberOfImages -eq 0 ]]
		then
			echo "There is no image files in "$inputDirectory"."
			return
	fi
}

CreateYearRepositories(){
	photoYears=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y | sort --unique)
	rm "$outputDirectory"/index.html
	for y in $photoYears
	do
		mkdir -p "$outputDirectory"/$y
		if [[ -f "$outputDirectory"/$y/index.html ]]
			then
				rm "$outputDirectory"/$y/index.html
		fi
		touch "$outputDirectory"/$y/index.html
		linkToRepository=$outputDirectory/$y/index.html
		echo "<a href="$linkToRepository">$y</a><br></br>">>index.html
	done
}

CreateDayDirectories(){
	for y in $photoYears
	do
		photoDays=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y_%m_%d | sort --unique | grep $y)
		for d in $photoDays
		do
			mkdir -p "$outputDirectory"/$y/$d
			mkdir -p "$outputDirectory"/$y/$d/.thumbs
		done
	done
}

MovePhotosToDirectories(){
	for img in $(ls "$inputDirectory" -a | grep ".png\|.PNG\|.jpg\|.JPG")
	do
		photoYear=$(exiftool -T -DateTimeOriginal "$inputDirectory"/$img -d %Y)
		photoDay=$(exiftool -T -DateTimeOriginal "$inputDirectory"/$img -d %Y_%m_%d)
		photoName="${photoDay} ${img}"
		cp -a "$inputDirectory"/$img "$outputDirectory"/"$photoYear"/"$photoDay"/"$photoName"
	done
}

inputDirectory="$1"
outputDirectory="$2"

CheckInputDirectory

if [[ ! -d "$outputDirectory" ]]
	then 
		mkdir "$outputDirectory"
		touch "$outputDirectory"/index.html
fi
CreateYearRepositories
CreateDayDirectories
MovePhotosToDirectories