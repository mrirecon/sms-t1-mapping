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
# Figure 4B and Figure 5 (right).

set -e

export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi

#---------------- Figure 4B -----------------------------
dir=../brain
dir1=..

# get mask for the center slice
bart slice 2 2 $dir/masks/vol_1-a-sms5_mask tmp_mask_center

# single-slice results
bart fmac $dir1/vol_1-a-ss-brain-0015-t1map.coo tmp_mask_center tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 0) tmp1 tmp
bart flip $(bart bitmask 1) tmp T1map_00

# spoke-interleaved results:
bart fmac $dir1/vol_1-inter5-center-brain-001-t1map.coo tmp_mask_center tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 0) tmp1 tmp
bart flip $(bart bitmask 1) tmp T1map_01

# sms-gaal results:
bart fmac $dir1/vol_1-sms5-gaal-center-brain-001-t1map.coo tmp_mask_center tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 0) tmp1 tmp
bart flip $(bart bitmask 1) tmp T1map_02

# sms-ga results:
bart extract 13 2 3 $dir1/vol_1-a-sms5-brain-001-t1map tmp0
bart fmac tmp0 tmp_mask_center tmp
bart transpose 0 1 tmp tmp1
bart flip $(bart bitmask 0) tmp1 tmp
bart flip $(bart bitmask 1) tmp T1map_03


beg=0
end=3

# join the T1 maps
bart join 0 `seq -f "T1map_0%g" $beg $end` T1map_comp



# Difference maps:
# contrain the T1 values to be larger than 0
bart join 2 `seq -f "T1map_0%g" $beg $end` tmp_all_maps
bart threshold -H 0 tmp_all_maps tmp_all_maps_0

# create a zero map 
dim0=$(bart show -d0 tmp_all_maps)
dim1=$(bart show -d1 tmp_all_maps)
dim2=$(bart show -d2 tmp_all_maps)

# contrain the T1 values to be lower than 10 seconds
bart zeros 3 $dim0 $dim1 $dim2 tmp_zeros
bart saxpy -- '-1.0' tmp_all_maps_0 tmp_zeros tmp_all_maps
bart threshold -H -- '-10.0' tmp_all_maps tmp_all_maps_threshed
bart saxpy -- '-1.0' tmp_all_maps_threshed tmp_zeros tmp_all_maps

# extract each-slice T1 map
for i in `seq $beg $end` 
do
        start=$((i))
        fin=$((i + 1))
        bart extract 2 $start $fin tmp_all_maps T1map_00$i
done

bart extract 2 0 1 tmp_zeros tmp_rela_diff_00

# relative difference between spoke-interleaved and single-slice T1 maps:
bart saxpy -- '-1.0' T1map_001 T1map_000 tmp0
bart invert T1map_000 tmp
bart fmac tmp0 tmp tmp_rela_diff_01

# relative difference between sms-gaal and single-slice T1 maps:
bart saxpy -- '-1.0' T1map_002 T1map_000 tmp0
bart fmac tmp0 tmp tmp_rela_diff_02

# relative difference between sms-ga and single-slice T1 maps:
bart saxpy -- '-1.0' T1map_003 T1map_00 tmp0
bart fmac tmp0 tmp tmp_rela_diff_03

# join the relative difference T1 maps
bart join 0 `seq -f "tmp_rela_diff_0%g" $beg $end` tmp_rela_diff_comp

# join both the comparisons of T1 and difference maps 
bart join 1 T1map_comp tmp_rela_diff_comp Fig04B


# ---------------- ROI mean T1s -------------------------
#---------------- Figure 5 (right) ----------------------
beg_comp=0
end_comp=3

for i in `seq $beg_comp $end_comp` 
do 
        bart transpose 1 0 T1map_0${i} T1map_00${i}
done

dim1=$(bart show -d0 T1map_000)
dim2=$(bart show -d0 T1map_000)

ROIs=4

beg=0
end=$((ROIs-1))

for j in `seq $beg_comp $end_comp` 
do
        for i in `seq $beg $end` 
        do      
                # mean calculation
                index=$((i+1))
                index1=$((j+1))
                bart avg $(bart bitmask 0 1) $dir/ROIs/vol_1_ROI${index} tmp_nROI${i}
                bart scale $((dim1 * dim2)) tmp_nROI${i} tmp1_nROI${i}
                bart invert tmp1_nROI${i} tmp2_nROI${i}
                bart fmac T1map_00${j} $dir/ROIs/vol_1_ROI${index} tmp_ROI
                bart avg $(bart bitmask 0 1) tmp_ROI tmp_ROI_T1
                bart scale $((dim1 * dim2)) tmp_ROI_T1 tmp_ROI_T1_1
                bart fmac tmp_ROI_T1_1 tmp2_nROI${i} tmp_mean_${j}_ROI${i}
        done
        bart join 0 `seq -f "tmp_mean_${j}_ROI%g" $beg $end` mean_ROIs${j}
done

bart join 1 `seq -f "mean_ROIs%g" $beg_comp $end_comp` mean_ROIs

rm *tmp*
rm T1map*
