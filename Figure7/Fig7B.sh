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
# Figure 7 B.

set -e

export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi

dir=../liver
dir1=..

bart squeeze $dir1/vol_1-a-sms3-liver-00025-t1map.coo tmp-t1map_1
bart fmac tmp-t1map_1 $dir/masks/vol_1-a-sms3_mask tmp-t1map_masked

slices=$(bart show -d2 tmp-t1map_masked)

beg=0
end=$((slices-1))

for i in `seq $beg $end` 
do
        start=$((i))
        fin=$((i + 1))
        bart extract 2 $start $fin tmp-t1map_masked tmp-t1map_masked_$i
        bart transpose 0 1 tmp-t1map_masked_$i tmp
        bart flip $(bart bitmask 1) tmp tmp-t1map_masked_1_$i
done

bart join 0 `seq -f "tmp-t1map_masked_1_%g" $end -1 $beg` tmp-t1map_masked_joint_1
bart resize -c 1 180 tmp-t1map_masked_joint_1 T1map_masked_joint


# Show All Single-slice results (3 slices)
foo=bac
for (( i=0; i<${#foo}; i++ )); do
        index=${foo:$i:1}
        start=$((i))
        fin=$((i + 1))
        bart fmac $dir1/vol_1-${index}-ss-liver-0005-t1map.coo $dir/masks/vol_1-ss_${index}_mask tmp_t1map_masked_${i}
        bart transpose 0 1 tmp_t1map_masked_${i} tmp
        bart flip $(bart bitmask 1) tmp tmp-ssl_t1map_masked_1_${i}
done


bart join 0 `seq -f "tmp-ssl_t1map_masked_1_%g" $end -1 $beg` tmp_t1map_masked_joint_1
bart resize -c 1 180 tmp_t1map_masked_joint_1 T1map-ssl_masked_joint

# Combine SMS results with single-slice results in one Figure
bart join 1 T1map_masked_joint T1map-ssl_masked_joint Fig07B

rm tmp*
rm T1map*