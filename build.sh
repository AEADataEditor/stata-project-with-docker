#!/bin/bash

# reading configuration


# if we are on Github Actions
if [[ $CI ]] 
then
   DOCKERIMG=$(echo $GITHUB_REPOSITORY | tr [A-Z] [a-z])
   TAG=latest
else
   source init.config.txt
   DOCKERIMG=$MYHUBID/$MYIMG
fi


# for debugging
BUILDARGS="--progress plain --no-cache"


if [[ -z $1 ]]
then
  echo "You need to specify the name of Stata license file as an argument"
  exit 2
fi
#STATALIC=$(readlink -m $1)
STATALIC=$1

if [[ ! -f $STATALIC ]] 
then
  echo "You specified $STATALIC - that is not a file"
	exit 2
fi


DOCKER_BUILDKIT=1 docker build \
  $BUILDARGS \
  . \
  --secret id=statalic,src=$STATALIC \
  -t ${DOCKERIMG}:$TAG

if [[ $? == 0 ]]
then
   # write out final values to config
   [[ -f config.txt ]] && \rm -i config.txt
   echo "# configuration created on $(date +%F_%H:%M)" | tee config.txt
   for name in $(grep -Ev '^#' init.config.txt| awk -F= ' { print $1 } ')
   do 
      echo ${name}=${!name} >> config.txt
   done
fi

      
      
   