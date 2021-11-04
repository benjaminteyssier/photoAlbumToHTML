#!/bin/bash
#
#Programme écrit par : Benjamin Teyssier
#Dernière version : 04/11/2022
#
#


#Affiche le manuel du logiciel
Help(){
   cat help.md
}


#Cette fonction vérifie que le répertoire d'entrée existe, contient au moins une image et contient au moins une image dotée d'un fichier exif.
CheckInputDirectory(){
	#On vérifie si le répertoire existe
	if [[ ! -d $inputDirectory ]]
		then
			echo "Directory "$inputDirectory" DOES NOT exists."
			return
	fi
	
	#On vérifie si le répertoire n'est pas vide d'images
	numberOfImages=$(ls "$inputDirectory" -a | grep ".png\|.PNG\|.jpg\|.JPG" | wc -l)
	if [[ $numberOfImages -eq 0 ]]
		then
			echo "There is no image files in "$inputDirectory"."
			return
	fi

	#On vérifie si le répertoire contient au moins une image dotée d'un fichier exif
	photoYears="$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y | sort --unique)"
	if [[ "$photoYears" == "-" ]]
		then
			echo "The images do not have exif data"
	fi
}

#Cette fonction extrait les différentes années de prises des photos et crée les répertoires associés dans le répertoire de sortie
CreateYearRepositories(){
	#Extraction des différentes années de prises des photos
	photoYears=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y | sort --unique)

	rm -f "$outputDirectory"/index.css 
	#Création du fichier css
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
	#Création du fichier html
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
		<link rel=\"stylesheet\" href=\"$outputDirectory/index.css\">
		<meta charset=\"utf-8\"/>
		</head>
		<body>
		<div class=\"header\">
		<h1>Album photo</h1>
		</div>"

	echo "$albumHtmlContent">>"$outputDirectory"/index.html
	#Création des répertoires des années et de leur fichier html
	for y in $photoYears
	do
		if [[ ! "$y" == "-" ]]
		then
			mkdir -p "$outputDirectory"/$y
			rm -f "$outputDirectory"/$y/index.html
			touch "$outputDirectory"/$y/index.html
			linkToRepository=$outputDirectory/$y/index.html
			#Ajout du lien du fichier html principal vers le fichier de l'année

			echo "<div class=\"year\"><a href=\"$linkToRepository\">$y</a></div>">>"$outputDirectory"/index.html
		fi
	done
	echo "</body></html>">>"$outputDirectory"/index.html
}

#Cette fonction extrait les différents jours de prise des photos et crée les répertoires associés dans les répertoires années correspondant
CreateDayDirectories(){
	for y in $photoYears
	do
		if [[ ! "$y" == "-" ]]
		then
			#Extraction des différents jours de prises de photo
			photoDays=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y_%m_%d | sort --unique | grep $y)
			for d in $photoDays
			do
				#Création du dossier reçevant les images
				mkdir -p "$outputDirectory"/$y/$d
				#Création du dossier reçevant les vignettes
				mkdir -p "$outputDirectory"/$y/$d/.thumbs
			done
		fi
	done
}

#Cette fonction déplace les photos du répertoire d'entrée vers le répertoire créé associé
MovePhotosToDirectories(){
	#Sélection des fichier de type image
	for img in $(ls "$inputDirectory" -a | grep ".png\|.PNG\|.jpg\|.JPG")
	do
		#Extraction de l'année de la prise de la photo img
		photoYear=$(exiftool -T -DateTimeOriginal "$inputDirectory"/$img -d %Y)
		if [[ ! "$photoYear" == "-" ]]
		then
			#Extraction du jour de la prise de la photo img
			photoDay=$(exiftool -T -DateTimeOriginal "$inputDirectory"/$img -d %Y_%m_%d)
			#Renommage de la photo
			photoName="${photoDay}_${img}"
			cp -a -n "$inputDirectory"/$img "$outputDirectory"/"$photoYear"/"$photoDay"/"$photoName"
		fi
	done
}

#Cette fonction crée les vignettes et les dépose dans les répertoires prévus à cet effet
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
					#Renommage de la vignette
					thumbName=$(echo "$img" | cut -f 1 -d '.')
					thumbName="${thumbName}-thumb.jpg"
					if [[ ! -f "$outputDirectory"/"$y"/"$d"/.thumbs/"$thumbName" ]]
					then
						#Redimensionnement des images avec ImageMagick pour obtenir une vignette de 150 de hauteur
						convert "$outputDirectory"/"$y"/"$d"/"$img" -geometry x150 "$outputDirectory"/"$y"/"$d"/.thumbs/"$thumbName"
					fi
				done
			done
		fi
	done
}

#Ecrit les liens des images à travers les vignettes dans le fichier html de l'année
FillYearIndex(){
	for y in $photoYears
	do
		if [[ ! "$y" == "-" ]]
		then
			yearHtmlContent="<!DOCTYPE html>
				<html>

				<head>
				<title>Mon année $y !</title>
				<link rel=\"stylesheet\" href=\"$outputDirectory/index.css\">
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
					linkToImage="$outputDirectory"/"$y"/"$d"/"$img"
					thumbName=$(echo "$img" | cut -f 1 -d '.')
					thumbName="${thumbName}-thumb.jpg"
					linkToThumb="$outputDirectory"/"$y"/"$d"/.thumbs/"$thumbName"
					#Crée un lien cliquable sous forme de vignette vers l'image correspondante
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
	#On instancie les repertoires d'entrée et de sortie donnés en arguments
	if [[ -z $1 ]]
	then
		echo "Please give an input directory"
	elif [[ -z $2 ]]
	then
		echo "Please give an outputDirectory"
	else
		inputDirectory="$1"
		outputDirectory="$2"
		#On vérifie que le répertoire d'entrée correspond aux attentes
		CheckInputDirectory
		mkdir -p "$outputDirectory"
		CreateYearRepositories
		CreateDayDirectories
		MovePhotosToDirectories
		CreateThumbs
		FillYearIndex
	fi

fi