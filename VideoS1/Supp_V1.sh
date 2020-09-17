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
# Supporting Video 1.

set -e

export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi

dir=../brain
dir1=..

slices=5
nTI=52
TR=4100
nspokes=208;
nspokes_per_frame=4

bart index 5 $nTI tmp1.coo
# use local index from newer bart with older bart
#./index 5 $num tmp1.coo
bart scale $(($nspokes_per_frame * $TR * $slices)) tmp1.coo tmp2.coo
bart ones 6 1 1 1 1 1 $nTI tmp1.coo 
bart saxpy $((($nspokes_per_frame * $slices / 2) * $TR)) tmp1.coo tmp2.coo tmp3.coo
bart scale 0.000001 tmp3.coo tmp_out_TI

bart extract 2 2 3 $dir/masks/vol_1-a-sms5_mask tmp_mask
bart resize -c 0 256 1 256 $dir1/vol_1-a-sms5-brain-reco-0005.coo tmp_maps_00
bart resize -c 0 256 1 256 $dir1/vol_1-a-sms5-brain-reco-001.coo tmp_maps_01
bart resize -c 0 256 1 256 $dir1/vol_1-a-sms5-brain-reco-0015.coo tmp_maps_02
bart resize -c 0 256 1 256 $dir1/vol_1-a-sms5-brain-reco-002.coo tmp_maps_03

beg=0
end=3

for i in `seq $beg $end` 
do
        start=$((i))
        fin=$((i + 1))
        bart extract 13 2 3 tmp_maps_0${i} tmp_maps
        bart fmac tmp_maps tmp_mask tmp_maps1
        bart slice 6 0 tmp_maps1 tmp_Mss
        bart cabs tmp_Mss tmp_Mss1
        bart slice 6 1 tmp_maps1 tmp_M0
        bart cabs tmp_M0 tmp_M01
        bart slice 6 2 tmp_maps1 tmp_R1s
        bart fmac tmp_out_TI tmp_R1s tmp_result
        bart scale  -- '-1.0' tmp_result  tmp_result1
        bart zexp tmp_result1 tmp_exp
        bart saxpy 2. tmp_M01 tmp_Mss1 tmp_result2
        bart fmac tmp_exp tmp_result2 tmp_result3
        bart repmat 5 $nTI tmp_Mss1 tmp_Mss
        bart saxpy -- '-1.0' tmp_result3 tmp_Mss tmp_relax
        bart transpose 0 1 tmp_relax tmp_relax1
        bart flip $(bart bitmask 0) tmp_relax1 tmp_relax
        bart flip $(bart bitmask 1) tmp_relax tmp_relax_sl0${i}
done

bart join 0 `seq -f "tmp_relax_sl0%g" $beg $end` relax

rm tmp*

