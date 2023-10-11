#!/bin/bash

FUZZER=$1     #fuzzer name (e.g., aflnet) -- this name must match the name of the fuzzer folder inside the Docker container
OUTDIR=$2     #name of the output folder
OPTIONS=$3    #all configured options -- to make it flexible, we only fix some options (e.g., -i, -o, -N) in this script
TIMEOUT=$4    #time for fuzzing
SKIPCOUNT=$5  #used for calculating cov over time. e.g., SKIPCOUNT=5 means we run gcovr after every 5 test cases

strstr() {
  [ "${1#*$2*}" = "$1" ] && return 1
  return 0
}

#Commands for afl-based fuzzers (e.g., aflnet, aflnwe)
if $(strstr $FUZZER "afl") || $(strstr $FUZZER "HNPFuzzer"); then

  # Run fuzzer-specific commands (if any)
  if [ -e ${WORKDIR}/run-${FUZZER} ]; then
    source ${WORKDIR}/run-${FUZZER}
  fi

  TARGET_DIR=${TARGET_DIR:-"proftpd"}
  INPUTS=${INPUTS:-${WORKDIR}"/in-ftp"}

  #Step-1. Do Fuzzing
  #Move to fuzzing folder
  cd $WORKDIR/${TARGET_DIR}
  if $(strstr $FUZZER "HNPFuzzer"); then
    AFL_PRELOAD=/home/ubuntu/${FUZZER}/sock2shm.so timeout -k 0 --preserve-status $TIMEOUT /home/ubuntu/${FUZZER}/afl-fuzz -d -i ${INPUTS} -o $OUTDIR -x ${WORKDIR}/ftp.dict -N tcp://127.0.0.1/21 $OPTIONS -c ${WORKDIR}/clean ./proftpd -n -c ${WORKDIR}/basic.conf
  else
    timeout -k 0 --preserve-status $TIMEOUT /home/ubuntu/${FUZZER}/afl-fuzz -d -i ${INPUTS} -o $OUTDIR -x ${WORKDIR}/ftp.dict -N tcp://127.0.0.1/21 $OPTIONS -c ${WORKDIR}/clean ./proftpd -n -c ${WORKDIR}/basic.conf -X
  fi 
  STATUS=$?

  #Step-2. Collect code coverage over time
  #Move to gcov folder
  cd $WORKDIR/proftpd-gcov

  #The last argument passed to cov_script should be 0 if the fuzzer is afl/nwe and it should be 1 if the fuzzer is based on aflnet
  #0: the test case is a concatenated message sequence -- there is no message boundary
  #1: the test case is a structured file keeping several request messages
  if [ $FUZZER = "aflnwe" ]; then
    cov_script ${WORKDIR}/${TARGET_DIR}/${OUTDIR}/ 21 ${SKIPCOUNT} ${WORKDIR}/${TARGET_DIR}/${OUTDIR}/cov_over_time.csv 0
  else
    cov_script ${WORKDIR}/${TARGET_DIR}/${OUTDIR}/ 21 ${SKIPCOUNT} ${WORKDIR}/${TARGET_DIR}/${OUTDIR}/cov_over_time.csv 1
  fi

  gcovr -r . --html --html-details -o index.html
  mkdir ${WORKDIR}/${TARGET_DIR}/${OUTDIR}/cov_html/
  cp *.html ${WORKDIR}/${TARGET_DIR}/${OUTDIR}/cov_html/

  #Step-3. Save the result to the ${WORKDIR} folder
  #Tar all results to a file
  cd ${WORKDIR}/${TARGET_DIR}
  tar -zcvf ${WORKDIR}/${OUTDIR}.tar.gz ${OUTDIR}

  exit $STATUS
fi