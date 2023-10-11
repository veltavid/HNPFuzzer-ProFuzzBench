#!/bin/bash

FUZZER=$1
TARDIR=$2
OUTDIR=$3
SKIPCOUNT=$4

cd $WORKDIR
if [ ! -d ${OUTDIR} ]; then
	mkdir ${OUTDIR}
fi

for result_file in "${WORKDIR}/${TARDIR}/"*; do
	file_name=$(basename ${result_file})
	rm -r out-dnsmasq*
	tar -xf $result_file
	rm -r out-dnsmasq-${FUZZER}/cov_html
	target_dir="$(pwd)/out-dnsmasq-${FUZZER}"
	pushd dnsmasq-gcov/src
	if [ $FUZZER = "aflnwe" ]; then
    		cov_script ${target_dir} 5353 ${SKIPCOUNT} ${target_dir}/cov_over_time.csv 0
	else
    		cov_script ${target_dir} 5353 ${SKIPCOUNT} ${target_dir}/cov_over_time.csv 1
	fi
	popd
	tar -zcf ${WORKDIR}/${OUTDIR}/${file_name} out-dnsmasq-${FUZZER}
done
