#!/bin/bash

if [[ -f config.txt ]]
then 
   configfile=config.txt
else 
   configfile=init.config.txt
fi

# name of the file to run
file=code/main.do


echo "================================"
echo "Pulling defaults from ${configfile}:"
cat $configfile
echo "--------------------------------"

source $configfile

echo "================================"
echo "Running docker:"
set -ev

# When we are on Github Actions
if [[ $CI ]] 
then
   DOCKEROPTS="--rm"
   DOCKERIMG=$(echo $GITHUB_REPOSITORY | tr [A-Z] [a-z])
   TAG=latest
else
   DOCKEROPTS="-it --rm -u $(id -u ${USER}):$(id -g ${USER}) "
   DOCKERIMG=$(echo $MYHUBID/$MYIMG | tr [A-Z] [a-z])
fi

# ensure that the directories are writable by Docker
chmod a+rwX code code/*
chmod a+rwX data 

# a few names
basefile=$(basename $file)
codedir=$(dirname $file)
logfile=${file%*.do}.log

# run the docker and the Stata file
# note that the working directory will be set to '/code' by default

time docker run $DOCKEROPTS \
  -v ${STATALIC}:/usr/local/stata/stata.lic \
  -v $(pwd)/:/project \
  -w /project/code  \
  $DOCKERIMG:$TAG -b $basefile

# print and check logfile

EXIT_CODE=0
if [[ -f $logfile ]]
then
   echo "===== $logfile ====="
   cat $logfile

   # Fail CI if Stata ran with an error
   LOG_CODE=$(tail -1 $logfile | tr -d '[:cntrl:]')
   echo "===== LOG CODE: $LOG_CODE ====="
   [[ ${LOG_CODE:0:1} == "r" ]] && EXIT_CODE=1 
else
   echo "$logfile not found"
   EXIT_CODE=2
fi
echo "==== Exiting with code $EXIT_CODE"
exit $EXIT_CODE


