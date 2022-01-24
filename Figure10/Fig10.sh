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
# Figure 10.

set -e


if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi
export PATH=$TOOLBOX_PATH:$PATH
export BART_COMPAT_VERSION="v0.7.00"

dir=../brain
dir1=..

sets=5 ### 5 sms acquisitions ###

beg=0
end=$((sets-1))

for i in `seq $beg $end` 
do
        start=$((i))
        fin=$((i + 1))
        bart squeeze $dir1/vol_1-${fin}-sms5-brain-001-t1map.coo tmp_vol_1-${fin}-sms5-brain-t1
        bart fmac tmp_vol_1-${fin}-sms5-brain-t1 $dir/masks/vol_1-whole-brain_mask_0${i} tmp_sms5-brain-t1-masked-0${i}
done

slices=$(bart show -d2 tmp_sms5-brain-t1-masked-00)

beg2=0
end2=$((slices-1))

for i in `seq $beg $end` ### for loop along set (sms acquisition) dimension ###
do
        start=$((i))
        fin=$((i+1))
        for j in `seq $beg2 $end2` ### for loop along slice dimension ###
        do
                start2=$((j))
                fin2=$((j+1))
                k=$((slices-1-j))
                bart extract 2 $start2 $fin2 tmp_sms5-brain-t1-masked-0${i} tmp
                bart transpose 0 1 tmp tmp1
                bart flip $(bart bitmask 1) tmp1 tmp
                bart flip $(bart bitmask 0) tmp T1map_0${i}_0${k}
        done
        bart join 1 `seq -f "T1map_0${i}_0%g" $beg $end` T1map_0${i}
done

bart join 0 `seq -f "T1map_0%g" $beg $end` Fig10

rm *tmp*
rm T1map*

