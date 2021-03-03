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

export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
	echo "\$TOOLBOX_PATH is not set correctly!" >&2
	exit 1
fi

helpstr=$(cat <<- EOF
Preparation of traj, data and inversion times for IR SMS Radial FLASH.

-s sample size 
-R repetition time
-G nth tiny golden angle
-p total number of spokes
-f number of spokes per frame (k-space)
-m sms factor
-S number of slices
-c number of spokes in the steady-state used for gradient delay correction
-h help

EOF
)

usage="Usage: $0 [-h] [-s sample] [-R TR] [-G GA] [-p nspokes] [-f nspokes_per_frame] [-m sms] [-S slices] [-c nstate] <input> <input_coil_index> <out_data> <out_traj> <out_TI>"

while getopts "hEs:R:G:p:f:m:S:c:" opt; do
	case $opt in
	h) 
		echo "$usage"
		echo "$helpstr"
		exit 0 
		;;		
	s) 
		sample_size=${OPTARG}
		;;
	R) 
		TR=${OPTARG}
		;;
	G) 
		GA=${OPTARG}
		;;
	p) 	
		nspokes=${OPTARG}
		;;
	f) 	
		nspokes_per_frame=${OPTARG}
		;;
	m) 	
		sms=${OPTARG}
		;;
	S) 	
		slices=${OPTARG}
		;;
	c) 	
		nstate=${OPTARG}
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done

shift $(($OPTIND -1 ))

nf=1

nf1=$((nspokes/nspokes_per_frame))

input=$(readlink -f "$1")

if [ $# -eq 4 ];
then
	out_data=$(readlink -f "$2")
	out_traj=$(readlink -f "$3")
	out_TI=$(readlink -f "$4")	
elif [ $# -eq 5 ];
then
	input_coil_index=$(readlink -f "$2")
	out_data=$(readlink -f "$3")
	out_traj=$(readlink -f "$4")
	out_TI=$(readlink -f "$5")
fi

if [ ! -e ${input}.cfl ] && [ ! -e ${input} ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi


#if [ ! -e $TOOLBOX_PATH/bart ] ; then
#        echo "\$TOOLBOX_PATH is not set correctly!" >&2
#        exit 1
#fi


# read data

WORKDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
trap 'rm -rf "$WORKDIR"' EXIT
cd $WORKDIR

bart extract 10 0 $nspokes $input ksp1
bart transpose 1 10 ksp1 ksp2

# Data preparation: switch dimensions to work with nufft tools
bart transpose 1 2 ksp2 temp
bart transpose 0 1 temp dataT

bart transpose 3 11 dataT dataT_temp
bart reshape $(bart bitmask 2 10) $nspokes_per_frame $nf1 dataT_temp dataT_temp1
bart transpose 3 11 dataT_temp1 dataT_final

#-----------------------------------------
# prepare data
#-----------------------------------------
if [ $# -eq 5 ]; 
then
# get the coil index
	n=0
	while read line; do
		bart slice 3 $line dataT_final tmpd-${n}.coo
		n=$(($n+1))
	done < $input_coil_index

	bart join 3 $(seq -f "tmpd-%g.coo" 0 $(($n-1))) dataT_final_coil_sel

	bart transpose 5 10 dataT_final_coil_sel dataT_final

	rm tmpd-*.coo

	# coil compression if the no. of coils is larger than 7
	if [[ $n -gt 7 ]]
	then
        	bart cc -A -p 8 dataT_final $out_data 
	else
        	bart scale 1. dataT_final $out_data 
	fi
elif [ $# -eq 4 ]; then
        bart cc -A -p 1 dataT_final data_final_cc
	bart transpose 5 10 data_final_cc $out_data 
fi


#-----------------------------------------
# Calculate trajectory
#-----------------------------------------
bart traj -r -D -G -x$sample_size -y1 -s$GA -m$sms -t$nspokes traj

bart extract 10 $((nspokes-nstate))  $nspokes traj traj_extract 
bart transpose 2 10 traj_extract traj_extract1
bart flip $(bart bitmask 2) traj_extract1 traj_extract_flip 

# extract steady-state data for gradient-delay correction
bart extract 2 $((nspokes-nstate)) $nspokes dataT dataT_extract
bart flip $(bart bitmask 2) dataT_extract dataT_extract_flip

# Calculate trajectory and do gradient delay correction
bart traj -D -r -G -x$sample_size -y1 -s$GA -m$sms -t$nspokes -q $(bart estdelay traj_extract_flip dataT_extract_flip) trajn
bart reshape $(bart bitmask 2 10) $nspokes_per_frame $nf1 trajn traj 
bart transpose 5 10 traj $out_traj


#-----------------------------------------
# calculate inversion times
#-----------------------------------------

bart index 5 $nf1 tmp1.coo
# use local index from newer bart with older bart
#./index 5 $num tmp1.coo
bart scale $(($nspokes_per_frame * $TR * $slices)) tmp1.coo tmp2.coo
bart ones 6 1 1 1 1 1 $nf1 tmp1.coo 
bart saxpy $((($nspokes_per_frame * $slices / 2) * $TR)) tmp1.coo tmp2.coo tmp3.coo
bart scale 0.000001 tmp3.coo $out_TI
