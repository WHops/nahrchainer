#!/bin/bash

set -euo pipefail 

# Loop over: 

TOTALLEN="500000"
SDLEN="500"
INTERSDDIST="1000"
INNERSDDIST="500"
FRACMATCH=1
CHUNKLEN="100"

#mkdir ../res
#mkdir ../benchmark

for STRAND in "+" "-"
do
for FRACMATCH in 0.99 0.95 0.90
do

for CHUNKLEN in 64 128 256 512 1024 2048 4096 
do
	for SDLEN in 64 128 256 512 1024 2048 4096 8192 16384 32768 65536
	do

	INNERSDDIST=${SDLEN}

	echo $CHUNKLEN
	# Create a chain of SDs
	./sample_bed_sd_files.R -t ${TOTALLEN} -s ${SDLEN} -i ${INTERSDDIST} -d ${INNERSDDIST} -m ${FRACMATCH} -o ../benchmark/run_${SDLEN}_${CHUNKLEN}_${FRACMATCH}_${STRAND}.txt -r ${STRAND}

	./sd_bed_format_and_qc.R ../benchmark/run_${SDLEN}_${CHUNKLEN}_${FRACMATCH}_${STRAND}.txt ../benchmark/run_${SDLEN}_${CHUNKLEN}_${FRACMATCH}_${STRAND}.tsv

	# Run seqbuilder
	Rscript seqbuilder_wrapper.R -l ${TOTALLEN} -s ../benchmark/run_${SDLEN}_${CHUNKLEN}_${FRACMATCH}_${STRAND}.tsv -o run_${SDLEN}_${CHUNKLEN}_${FRACMATCH}_${STRAND} -c ${CHUNKLEN}

	# Test output
	./sd_compare_input_output.R -p ../res/paf/run_${SDLEN}_${CHUNKLEN}_${FRACMATCH}_${STRAND}_chunked.paf -q ../benchmark/run_${SDLEN}_${CHUNKLEN}_${FRACMATCH}_${STRAND}.tsv -n run_${SDLEN}_${CHUNKLEN}_${FRACMATCH}_${STRAND} -o ../resfile3.txt -c ${CHUNKLEN} -r ${STRAND}
	done
done
done
done
