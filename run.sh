#!/bin/bash

if [[ -z $1 ]]
then
  echo "You need to specify the name of Stata license file as an argument"
  exit 2
fi
STATALIC=$(readlink -m $1)

if [[ ! -f $STATALIC ]] 
then
  echo "You specified $STATALIC - that is not a file"
	exit 2
fi

# When we are on Github Actions
if [[ $CI ]] 
then
   DOCKEROPTS="--rm"
   DOCKERIMG=$(echo $GITHUB_REPOSITORY | tr [A-Z] [a-z])
   TAG=latest
else
   DOCKEROPTS="-it --rm"
   source .versions
   DOCKERIMG=$MYHUBID/$MYIMG
fi

# ensure that the directories are writable by Docker
chmod a+rwX code 
chmod a+rwX data

# run the docker and the Stata file
# note that the working directory will be set to '/code' by default

docker run $DOCKEROPTS \
  -v ${STATALIC}:/usr/local/stata/stata.lic \
  -v $(pwd)/code:/code \
  -v $(pwd)/data:/data \
  $DOCKERIMG:$TAG -b main.do

