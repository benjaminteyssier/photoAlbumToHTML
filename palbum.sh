#!/bin/bash
#
#Written by Benjamin Teyssier
#Last version : 04/11/2022
#
#


#Display software manual
Help(){
   cat help.md
}

#This function checks if the input directory exists and is valid
CheckInputDirectory(){
	#Check if the input directory exists
	if [[ ! -d $inputDirectory ]]
		then
			echo "Directory "$inputDirectory" DOES NOT exists."
			return
	fi
	
	#Check if there are images in the directory
	numberOfImages=$(ls "$inputDirectory" -a | grep ".png\|.PNG\|.jpg\|.JPG" | wc -l)
	if [[ $numberOfImages -eq 0 ]]
		then
			echo "There is no image files in "$inputDirectory"."
			return
	fi

	#Check if at least one image has exif data
	photoYears="$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y | sort --unique)"
	if [[ "$photoYears" == "-" ]]
		then
			echo "The images do not have exif data"
	fi
}

#This function extracts the different years when photos were taken and creates the matching directories in the output directory
CreateYearRepositories(){
	#Extraction of the years photo were taken
	photoYears=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y | sort --unique)

	rm -f "$outputDirectory"/index.css 
	#Create CSS file
	touch "$outputDirectory"/index.css
	    echo "
    photo {
    border: thin #c0c0c0 solid;
    display: flex;
    flex-flow: column;
    padding: 5px;
    max-width: 220px;
    margin: auto;
    }

    .header {
    padding: 30px;
    text-align: center;
    background: #36a6c7;
    font : arial
    color: white;
    font-size: 30px;
    }

    .year, .year:visited {
    border: 3px #1a5e92 solid;
    display: flex;
    float: left;
    background-color: white;
    color: #fff;
    font: smaller arial;
    padding: 10px;
    text-align: center;
    font-size: 40px;
    margin : 10px;
    }

    a:link, a:visited{
    	text-decoration : none;
    	color : black;
    	display: inline-block;
    }

    .year:hover{	
    	border: 3px #1a5e92 solid;
	   display: flex;
	   float: left;
	   background-color: #70befa;
	   color: #fff;
	   font: smaller arial;
	   padding: 10px;
	   text-align: center;
	   font-size: 40px;
	   margin : 10px;
    }

    body {
    color: black;
    }

    img {
    max-width: 220px;
    max-height: 150px;
    margin : auto;
    text-align:center;
    display : block

    }

    .img_div{
        float: left;
        padding: 20px;
        border: 3px #1a5e92 solid;
        background-color: white;
        margin : 10px;
    }

    .img_div:hover{
        float: left;
        padding: 20px;
        border: 3px #1a5e92 solid;
        background-color: #70befa;
    }

    figcaption {
	    background-color: #222;
	    color: #fff;
	    font: italic smaller sans-serif;
	    padding: 3px;
	    text-align: center;
    }




    }">>"$outputDirectory"/index.css
	rm -f "$outputDirectory"/index.html
	#Create root HTML file
	touch "$outputDirectory"/index.html

	albumHtmlContent="<!DOCTYPE html    figcaption {
    background-color: #222;
    color: #fff;
    font: italic smaller sans-serif;
    padding: 3px;
    text-align: center;
    }>
		<html>

		<head>
		<title>Album photo</title>
		<link rel=\"stylesheet\" href=\"index.css\">
		<meta charset=\"utf-8\"/>
		</head>
		<body>
		<div class=\"header\">
		<h1>Album photo</h1>
		</div>"

	echo "$albumHtmlContent">>"$outputDirectory"/index.html
	#Create year repositories and their associated HTML file
	for y in $photoYears
	do
		if [[ ! "$y" == "-" ]]
		then
			mkdir -p "$outputDirectory"/$y
			rm -f "$outputDirectory"/$y/index.html
			touch "$outputDirectory"/$y/index.html
			linkToRepository=$y/index.html
			#Add link to the year HTML file inside the root one

			echo "<div class=\"year\"><a href=\"$linkToRepository\">$y</a></div>">>"$outputDirectory"/index.html
		fi
	done
	echo "</body></html>">>"$outputDirectory"/index.html
}

#Extract the days on which photos were taken and create the matching directories
CreateDayDirectories(){
	for y in $photoYears
	do
		if [[ ! "$y" == "-" ]]
		then
			#Extract the days on which photos were taken
			photoDays=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y_%m_%d | sort --unique | grep $y)
			for d in $photoDays
			do
				#Create the directory receiving the images
				mkdir -p "$outputDirectory"/$y/$d
				#Create the directory receiving the thumbs
				mkdir -p "$outputDirectory"/$y/$d/.thumbs
			done
		fi
	done
}

#Move the photos from the input directory to the right directory
MovePhotosToDirectories(){
	#Select the image files in the input directory
	for img in $(ls "$inputDirectory" -a | grep ".png\|.PNG\|.jpg\|.JPG")
	do
		#Extract the year of the photo
		photoYear=$(exiftool -T -DateTimeOriginal "$inputDirectory"/$img -d %Y)
		if [[ ! "$photoYear" == "-" ]]
		then
			#Extract the day of the photo
			photoDay=$(exiftool -T -DateTimeOriginal "$inputDirectory"/$img -d %Y_%m_%d)
			#Rename the photo
			photoName="${photoDay}_${img}"
			cp -a -n "$inputDirectory"/$img "$outputDirectory"/"$photoYear"/"$photoDay"/"$photoName"
		fi
	done
}

#Create the thumbs and move them to their directory
CreateThumbs(){
	for y in $photoYears
	do
		if [[ ! "$y" == "-" ]]
		then
			photoDays=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y_%m_%d | sort --unique | grep $y)
			for d in $photoDays
			do
				for img in $(ls "$outputDirectory"/"$y"/"$d" )
				do
					#Rename the thumb
					thumbName=$(echo "$img" | cut -f 1 -d '.')
					thumbName="${thumbName}-thumb.jpg"
					if [[ ! -f "$outputDirectory"/"$y"/"$d"/.thumbs/"$thumbName" ]]
					then
						#Size the image to 150px
						convert "$outputDirectory"/"$y"/"$d"/"$img" -geometry x150 "$outputDirectory"/"$y"/"$d"/.thumbs/"$thumbName"
					fi
				done
			done
		fi
	done
}

#Write the links of the image in the year HTML file
FillYearIndex(){
	for y in $photoYears
	do
		if [[ ! "$y" == "-" ]]
		then
			yearHtmlContent="<!DOCTYPE html>
				<html>

				<head>
				<title>Mon année $y !</title>
				<link rel=\"stylesheet\" href=\"../index.css\">
				<meta charset=\"utf-8\"/>
				</head>
				<body>
				<div class=\"header\">
				<h1>Mon année $y !</h1>
				</div>"
			echo "$yearHtmlContent" >> "$outputDirectory"/"$y"/index.html
			photoDays=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y_%m_%d | sort --unique | grep $y)
			for d in $photoDays
			do
				for img in $(ls "$outputDirectory"/"$y"/"$d" ) 
				do
					linkToImage="$d"/"$img"
					thumbName=$(echo "$img" | cut -f 1 -d '.')
					thumbName="${thumbName}-thumb.jpg"
					linkToThumb="$d"/.thumbs/"$thumbName"
					#Create a link to the image
					echo "<div class=\"img_div\"><a href=\"$linkToImage\"><img src=\"$linkToThumb\"><figcaption>$img</figcaption></a></div>">>"$outputDirectory"/"$y"/index.html
				done
			done
			echo "</body></html>" >> "$outputDirectory"/"$y"/index.html
		fi
	done
}

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]
then
	Help
elif ! command -v convert &> /dev/null
then
	echo "Please check you have installed ImageMagick"
elif ! command -v exiftool &> /dev/null
then
	echo "Please check you have installed exiftool"
else
	if [[ -z $1 ]]
	then
		echo "Please give an input directory"
	elif [[ -z $2 ]]
	then
		echo "Please give an outputDirectory"
	else
		inputDirectory="$1"
		outputDirectory="$2"
		CheckInputDirectory
		mkdir -p "$outputDirectory"
		CreateYearRepositories
		CreateDayDirectories
		MovePhotosToDirectories
		CreateThumbs
		FillYearIndex
	fi

fi