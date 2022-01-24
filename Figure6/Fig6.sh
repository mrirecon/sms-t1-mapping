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
# Figure 6.

set -e


if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi
export PATH=$TOOLBOX_PATH:$PATH
export BART_COMPAT_VERSION="v0.7.00"

dir=../liver
dir1=..

# single-slice results
bart fmac $dir1/vol_1-a-ss-liver-0005-t1map.coo $dir/masks/vol_1-ss_a_mask tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 1) tmp1 tmp_T1map_00
bart resize -c 1 180 tmp_T1map_00 T1map_00

# spoke-interleaved results:
bart fmac $dir1/vol_1-inter3-center-liver-00025-t1map.coo $dir/masks/vol_1-inter3_mask tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 1) tmp1 tmp_T1map_01
bart resize -c 1 180 tmp_T1map_01 T1map_01

# sms-gaal results:
bart fmac $dir1/vol_1-sms3-gaal-center-liver-00025-t1map.coo $dir/masks/vol_1-sms3-aligned_mask tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 1) tmp1 tmp_T1map_02
bart resize -c 1 180 tmp_T1map_02 T1map_02

# sms-ga results:
bart squeeze $dir1/vol_1-a-sms3-liver-00025-t1map.coo tmp_sms_t1
bart fmac tmp_sms_t1 $dir/masks/vol_1-a-sms3_mask tmp_sms_t1_masked
bart extract 2 1 2 tmp_sms_t1_masked tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 1) tmp1 tmp_T1map_03
bart resize -c 1 180 tmp_T1map_03 T1map_03

beg=0
end=3

# Show the comparisons
bart join 0 `seq -f "T1map_0%g" $beg $end` Fig06A

# --------------- ROI mean T1 calculations --------------
#---------------------- Figure 6B -----------------------

for i in `seq $beg $end` 
do 
        bart transpose 1 0 tmp_T1map_0${i} tmp_T1map_00${i}
        bart flip $(bart bitmask 0) tmp_T1map_00${i} T1map_00${i}
done

for i in `seq $beg $end` 
do      
        # mean calculation
        bart avg $(bart bitmask 0 1) $dir/ROIs/vol_1_ROI tmp_nROI${i}
        bart scale $((dim1 * dim2)) tmp_nROI${i} tmp1_nROI${i}
        bart invert tmp1_nROI${i} tmp2_nROI${i}
        bart fmac T1map_00${i} $dir/ROIs/vol_1_ROI tmp_ROI
        bart avg $(bart bitmask 0 1) tmp_ROI tmp_ROI_T1
        bart scale $((dim1 * dim2)) tmp_ROI_T1 tmp_ROI_T1_1
        bart fmac tmp_ROI_T1_1 tmp2_nROI${i} tmp_mean_ROI${i}
done
bart join 0 `seq -f "tmp_mean_ROI%g" $beg $end` mean_ROIs

rm tmp*
rm T1map*
