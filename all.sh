#!/bin/bash
# 
# Copyright 2020. Uecker Lab, University Medical Center Goettingen.
#
# Author: Xiaoqing Wang, 2020
# xiaoqing.wang@med.uni-goettingen.de
#
# Wang X et al.
# Model‐Based Reconstruction for Simultaneous Multi‐Slice T1 Mapping 
# using Single‐Shot Inversion‐Recovery Radial FLASH.
# Magn Reson Med. 2020
#
# run all model-based reconstructions

set -e

export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi

# phantom
./run_ss_phantom.sh 

./run_sms3_phantom.sh 

# brain
./run_ss_brain.sh $(seq 1 6)

./run_inter3_brain.sh

./run_sms3_gaal_brain.sh

./run_sms3_brain.sh $(seq 1 2)

./run_inter5_brain.sh

./run_sms5_gaal_brain.sh

./run_sms5_brain.sh $(seq 1 6)

# liver
./run_ss_liver.sh $(seq 1 6)

./run_inter3_liver.sh

./run_sms3_gaal_liver.sh

./run_sms3_liver.sh $(seq 1 6)
