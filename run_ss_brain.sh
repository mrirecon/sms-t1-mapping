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


if [ $# -eq 0 ]; then
	vols=1
else
	vols=$*
fi

scans=(a b c d e)

dir=brain/ss

sample=512
res=$(($sample/2))
TR=4100
GA=7
lambda=0.0015
reg=${lambda: 2:5}
nstate=180
overgrid=1.25

nspokes=1020;
nspokes_per_frame=15
sms=1
slices=$sms

for i in ${vols[@]} ; do
        for j in ${scans[@]} ; do

		prefix=vol_${i}-${j}

                echo $prefix
                
                bart scale 1. $dir/$prefix data/_ksp
	        ./prep.sh -s$sample -R$TR -G$GA -p$nspokes -f$nspokes_per_frame -m$sms -S$slices -c$nstate data/_ksp ${prefix}-data.coo ${prefix}-traj.coo ${prefix}-TI.coo
	        ./reco.sh -m$sms -R$lambda -o$overgrid ${prefix}-TI.coo ${prefix}-traj.coo ${prefix}-data.coo ${prefix}-ss-brain-reco-${reg}.coo | tee -a $prefix.log
	        ./post.sh -R$TR -r$res ${prefix}-ss-brain-reco-${reg}.coo ${prefix}-ss-brain-${reg}-t1map.coo
                rm ${prefix}-traj.coo ${prefix}-data.coo
        done
done
