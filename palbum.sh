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
	rm -f "$outputDirectory"/index.html
	#Création du fichier html
	touch "$outputDirectory"/index.html
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
			echo "<a href=\"$linkToRepository\">$y</a><br></br>">>"$outputDirectory"/index.html
		fi
	done
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
				mkdir -p "$outputDirectory"/$y/$d
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
		photoYear=$(exiftool -T -DateTimeOriginal "$inputDirectory"/$img -d %Y)
		if [[ ! "$photoYear" == "-" ]]
		then
			photoDay=$(exiftool -T -DateTimeOriginal "$inputDirectory"/$img -d %Y_%m_%d)
			photoName="${photoDay}_${img}"
			cp -a -n "$inputDirectory"/$img "$outputDirectory"/"$photoYear"/"$photoDay"/"$photoName"
		fi
	done
}

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
					thumbName=$(echo "$img" | cut -f 1 -d '.')
					thumbName="${thumbName}-thumb.jpg"
					if [[ ! -f "$outputDirectory"/"$y"/"$d"/.thumbs/"$thumbName" ]]
					then
						convert "$outputDirectory"/"$y"/"$d"/"$img" -geometry x150 "$outputDirectory"/"$y"/"$d"/.thumbs/"$thumbName"
					fi
				done
			done
		fi
	done
}

FillYearIndex(){
	for y in $photoYears
	do
		if [[ ! "$y" == "-" ]]
		then
			photoDays=$(exiftool -T -DateTimeOriginal "$inputDirectory" -d %Y_%m_%d | sort --unique | grep $y)
			for d in $photoDays
			do
				for img in $(ls "$outputDirectory"/"$y"/"$d" ) 
				do
					linkToImage="$outputDirectory"/"$y"/"$d"/"$img"
					thumbName=$(echo "$img" | cut -f 1 -d '.')
					thumbName="${thumbName}-thumb.jpg"
					linkToThumb="$outputDirectory"/"$y"/"$d"/.thumbs/"$thumbName"
					echo "<a href=\"$linkToImage\"><img src=\"$linkToThumb\" alt=\"alternate_text\"></a>">>"$outputDirectory"/"$y"/index.html
				done
			done
		fi
	done
}

#On instancie les repertoires d'entrée et de sortie donnés en arguments
inputDirectory="$1"
outputDirectory="$2"


#On vérifie que le répertoire d'entrée correspond aux attentes
CheckInputDirectory

mkdir -p "$outputDirectory"
CreateYearRepositories
echo 1
CreateDayDirectories
echo 2
MovePhotosToDirectories
echo 3
CreateThumbs
echo 4
FillYearIndex
echo 5