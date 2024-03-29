#!/bin/bash

#environnement argument
environnement=$1
srcPath=$2

  if [ -z $environnement ]; then
    echo "Environnement is missing"
    exit -1
  elif [ -z $srcPath ]; then
    echo "SRC path is missing"
    exit -1
  elif [ $environnement != 'prod' ] && [ $environnement != 'recette' ]; then
    echo "Environnement is wrong, should be prod or recette"
    exit -1
  fi

source "${srcPath}/variables.prod"

echo "*******************************************************"
echo "Scripts vars"
echo "*******************************************************"
echo "Deploy path : $deployPath "
echo "Config path : $configPath "
echo "Git repo : $gitPath "
echo "Release date : $releaseDate "
echo "Choosen tag: $versionTag "


#change dir to app path
cd $deployPath
pwd

echo "*******************************************************"
echo "Cloning tag into releases directory"
echo "*******************************************************"
if [ -z $versionTag ]; then
  git clone --single-branch $gitPath $releaseDate
else
  git clone -b ${versionTag}  --single-branch $gitPath $releaseDate
fi

cd $releaseDate
pwd

# Install new composer packages
echo "*******************************************************"
echo "INSTALLING COMPOSER PACKAGES"
echo "*******************************************************"
composer install --no-dev --prefer-dist --optimize-autoloader
echo ' '

echo "*******************************************************"
echo "Setup environnement .htaccess"
echo "*******************************************************"
pwd
if [ -f ".htaccess.${environnement}" ]; then
    cp ".htaccess.${environnement}" .htaccess
    echo "Setting .htaccess.${environnement}"
fi

echo "*******************************************************"
echo "Creating sylinkks for shared folders"
echo "*******************************************************"
pwd
for folder in "${shared[@]}"
do
   :
   cd ${deployPath}
   cd ../
   pwd   
   if [ ! -d "shared/${folder}" ]; then
       mkdir -p "shared/${folder}"
       chmod -R 0775 "shared/${folder}/"
       echo " -> Creating directory: shared/${folder}"
   fi
done

cd ${deployPath}
cd $releaseDate
pwd
for folder in "${shared[@]}"
do
   :
   ln -s "../../shared/${folder}" ${folder}
done

echo "*******************************************************"
echo "Removing old current symlink"
echo "*******************************************************"
cd ${deployPath}
pwd
cd ../
pwd
rm current

echo "*******************************************************"
echo "Creating SymLink current"
pwd
echo "*******************************************************"
ln -s releases/${releaseDate} current

echo "*******************************************************"
echo "Removing previous versions"
echo "*******************************************************"
cd releases/
shopt -s dotglob
shopt -s nullglob
array=(*/)
for dir in "${array[@]}"; do echo "$dir"; done

# Unset shell option after use, if desired. Nullglob
# is unset by default.
shopt -u dotglob
shopt -u nullglob

#if more than 3 folders in releases we will remove olds one
arraySize=${#array[@]}

echo "Array size is ${arraySize} "
if [ "${arraySize}" -gt 3 ]; then
        echo "removing old version ${array[0]}"
        rm -rf ${array[0]}
fi

exit
