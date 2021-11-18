#!/bin/bash

if [[ -z $1 ]]
then
  echo "You need to specify the name of Stata license file as an argument"
  exit 2
fi
STATALIC=$(readlink -m $1)

DOCKEROPTS="-it --rm"
# When we are on Github Actions
[[ $CI ]] && DOCKEROPTS="--rm"

if [[ ! -f $STATALIC ]] 
then
  echo "You specified $STATALIC - that is not a file"
	exit 2
fi

source .versions

docker run $DOCKEROPTS \
  -v ${STATALIC}:/usr/local/stata/stata.lic \
  -v $(pwd)/code:/code \
  -v $(pwd)/data:/data \
  $MYHUBID/$MYIMG:$TAG -b main.do

