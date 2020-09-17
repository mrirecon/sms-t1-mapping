#!/bin/bash

ZENODO_RECORD=3969809

# load phantom data
for i in phantom-ss phantom-sms3 phantom-ROIs; do

	./load.sh ${ZENODO_RECORD} ${i} .
	tar -xzvf ${i}.tgz
done

# load brain data
for i in brain-ss brain-inter3 brain-sms3-aligned brain-sms3 brain-inter5 brain-sms5-aligned brain-sms5 brain-sms5-whole_brain brain-ROIs; do

	./load.sh ${ZENODO_RECORD} ${i} .
	tar -xzvf ${i}.tgz
done

# # load liver data
for i in liver-ss liver-inter3 liver-sms3-aligned liver-sms3 liver-ROIs; do

	./load.sh ${ZENODO_RECORD} ${i} .
	tar -xzvf ${i}.tgz
done
