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
# Figure 3.

set -e


if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi
export PATH=$TOOLBOX_PATH:$PATH
export BART_COMPAT_VERSION="v0.7.00"

dir=../brain
dir1=..

# get mask for the center slice
bart slice 2 2 $dir/masks/vol_1-a-sms5_mask tmp_mask_center

# reg 0.0005:
bart extract 13 2 3 $dir1/vol_1-a-sms5-brain-0005-t1map.coo tmp0
bart fmac tmp0 tmp_mask_center tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 0) tmp1 tmp
bart flip $(bart bitmask 1) tmp T1map_00

# reg 0.001:
bart extract 13 2 3 $dir1/vol_1-a-sms5-brain-001-t1map.coo tmp0
bart fmac tmp0 tmp_mask_center tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 0) tmp1 tmp
bart flip $(bart bitmask 1) tmp T1map_01

# reg 0.0015:
bart extract 13 2 3 $dir1/vol_1-a-sms5-brain-0015-t1map.coo tmp0
bart fmac tmp0 tmp_mask_center tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 0) tmp1 tmp
bart flip $(bart bitmask 1) tmp T1map_02

# reg 0.002:
bart extract 13 2 3 $dir1/vol_1-a-sms5-brain-002-t1map.coo tmp0
bart fmac tmp0 tmp_mask_center tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 0) tmp1 tmp
bart flip $(bart bitmask 1) tmp T1map_03

# join the results together
beg=0
end=3
bart join 0 `seq -f "T1map_0%g" $beg $end` Fig03


rm *tmp*
rm T1map*



