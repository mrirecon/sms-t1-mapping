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

set -e


if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi
export PATH=$TOOLBOX_PATH:$PATH
export BART_COMPAT_VERSION="v0.7.00"

dir=brain/inter3

sample=512
res=$((sample / 2))
TR=4100
GA=7
lambda=0.001
reg=${lambda: 2:5}
nstate=60
overgrid=1.25

nspokes=330;
nspokes_per_frame=5
sms=1
slices=3


prefix=vol_1-inter3-center

echo $prefix
                
bart scale 1. $dir/$prefix data/_ksp
./prep.sh -s$sample -R$TR -G$GA -p$nspokes -f$nspokes_per_frame -m$sms -S$slices -c$nstate data/_ksp ${prefix}-data.coo ${prefix}-traj.coo ${prefix}-TI.coo
./reco.sh -m$sms -R$lambda -o$overgrid ${prefix}-TI.coo ${prefix}-traj.coo ${prefix}-data.coo ${prefix}-brain-reco-${reg}.coo | tee -a $prefix.log
./post.sh -R$TR -r$res ${prefix}-brain-reco-${reg}.coo ${prefix}-brain-${reg}-t1map.coo
rm ${prefix}-traj.coo ${prefix}-data.coo
