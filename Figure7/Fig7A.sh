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
# Figure 7 A.

set -e


if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi
export PATH=$TOOLBOX_PATH:$PATH
export BART_COMPAT_VERSION="v0.7.00"

# Show all SMS 5 results
dir=../brain
dir1=..

bart squeeze $dir1/vol_1-a-sms5-brain-001-t1map.coo tmp_sms5_t1
bart fmac tmp_sms5_t1 $dir/masks/vol_1-a-sms5_mask tmp_t1map_masked

slices=$(bart show -d2 tmp_t1map_masked)

beg=0
end=$((slices-1))

for i in `seq $beg $end` 
do
        start=$((i))
        fin=$((i + 1))
        bart extract 2 $start $fin tmp_t1map_masked tmp_t1map_masked_$i
        bart transpose 0 1 tmp_t1map_masked_$i tmp
        bart flip $(bart bitmask 1) tmp tmp1
        bart flip $(bart bitmask 0) tmp1 tmp_t1map_masked_1_$i
done

bart join 0 `seq -f "tmp_t1map_masked_1_%g" $beg $end` T1map_masked_joint


# Show all single-slice results (5 slices)

foo=cbade
for (( i=0; i<${#foo}; i++ )); do
        index=${foo:$i:1}
        start=$((i))
        fin=$((i + 1))
        bart extract 2 $i $((i+1)) $dir/masks/vol_1-a-sms5_mask tmp_mask_${i}
        bart fmac $dir1/vol_1-${index}-ss-brain-0015-t1map.coo tmp_mask_${i} tmp_t1map_masked
        bart transpose 0 1 tmp_t1map_masked tmp
        bart flip $(bart bitmask 1) tmp tmp1
        bart flip $(bart bitmask 0) tmp1 tmp_t1map_masked_${i}
done

bart join 0 `seq -f "tmp_t1map_masked_%g" $beg $end` T1map_ssl_masked

# Combine SMS results with single-slice results in one Figure
bart join 1 T1map_masked_joint T1map_ssl_masked Fig07A

rm tmp*
rm T1map*
