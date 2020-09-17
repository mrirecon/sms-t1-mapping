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
# Figure 2.

set -e

export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi

#---------------- Figure 2A -----------------------------
dir=../phantom
dir1=../

# masking the sms T1 maps
bart squeeze $dir1/pha-sms3-001-t1map.coo tmp
bart transpose 0 1 tmp tmp_t1
bart flip $(bart bitmask 0) $dir/phantom_mask tmp_mask1
bart transpose 0 1 tmp_mask1 tmp_mask0
bart fmac tmp_t1 tmp_mask0 T1map-masked

# separate sms T1 maps
slices=$(bart show -d2 T1map-masked)

beg=0
end=$((slices-1))

for i in `seq $beg $end` 
do
        start=$((i))
        fin=$((i + 1))
        bart extract 2 $start $fin T1map-masked T1map_0${i}
done

bart join 0 `seq -f "T1map_0%g" $beg $end` T1map_sms

# single-slice T1 map
bart extract 2 1 2 tmp_mask0 tmp-mask
bart transpose 0 1 $dir1/pha-ss-0015-t1map.coo T1map_ssl1
bart fmac tmp-mask T1map_ssl1 T1map_ssl

# join single-slice and sms T1 maps
bart join 0 T1map_ssl T1map_sms Fig02A

# -------------------- ROI mean T1s ---------------------
#--------------------- Figure 2B ----------------------

bart transpose 1 0 T1map_ssl T1map_000
bart transpose 1 0 T1map_01 T1map_001

dim1=$(bart show -d0 T1map_000)
dim2=$(bart show -d0 T1map_000)

ROIs=6

beg=0
end=$((ROIs-1))

for j in {0..1}
do
        for i in `seq $beg $end` 
        do      
                # mean calculation
                bart slice 2 $i $dir/slice_a_ROIs ROI_${i}
                bart avg $(bart bitmask 0 1) ROI_${i} tmp_nROI${i}
                bart scale $((dim1 * dim2)) tmp_nROI${i} tmp1_nROI${i}
                bart invert tmp1_nROI${i} tmp2_nROI${i}
                bart fmac T1map_00${j} ROI_${i} tmp_ROI
                bart avg $(bart bitmask 0 1) tmp_ROI tmp_ROI_T1
                bart scale $((dim1 * dim2)) tmp_ROI_T1 tmp_ROI_T1_1
                bart fmac tmp_ROI_T1_1 tmp2_nROI${i} tmp_mean_${j}_ROI${i}
        done
        bart join 0 `seq -f "tmp_mean_${j}_ROI%g" $beg $end` mean_ROIs${j}
done

bart join 1 mean_ROIs0 mean_ROIs1 mean_ROIs


rm *tmp*
rm T1map*
