#! /bin/bash

RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[33;5m"
NONE="\e[0m"

status="true"
while $status;
do
read -p "Enter the registry host ---> " reg
read -p "Enter a relevant image to pull & push, for multiple images use a spaces! ---> " img
    # Check the answers if is valid
    if [ -z $reg ]; then echo -e $RED"An empty registry host is not accepted"$NONE; else status="false"; fi
    if [ -z $img ]; then echo -e $RED"An empty list of images is not accepted"$NONE; else status="false"; fi
done

declare -a list=($img)
echo $list
for i in "${list[@]}";
do
    docker pull $i
    docker tag $i $reg/$i
    docker push $reg/$i
    echo -e $GREEN"Image $reg/$i is successfully pushed --->"$NONE
done