#!/bin/bash

source .versions

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
  -t $MYHUBID/${MYIMG}:$TAG
