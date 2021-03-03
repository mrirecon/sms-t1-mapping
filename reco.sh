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

usage="Usage: $0 [-m sms] [-R lambda] [-k] [-o overgrid] <TI> <traj> <ksp> <output> <output_sens>"

if [ $# -lt 4 ] ; then

        echo "$usage" >&2
        exit 1
fi

k_filter=0

while getopts "hm:R:ko:" opt; do
	case $opt in
	h) 
		echo "$usage"
		exit 0 
		;;		
	m) 
		sms=${OPTARG}
		;;
	R) 
		lambda=${OPTARG}
		;;
	k)
		k_filter=1
		;;
	o)
		overgrid=${OPTARG}
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))

TI=$(readlink -f "$1")
traj=$(readlink -f "$2")
ksp=$(readlink -f "$3")
reco=$(readlink -f "$4")

if [ "$#" -lt 5 ] ; then
        sens=""
else
	sens=$(readlink -f "$5")
fi

if [ ! -e $TI ] ; then
        echo "Input file 'TI' does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e $traj ] ; then
        echo "Input file 'traj' does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e $ksp ] ; then
        echo "Input file 'ksp' does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
        echo "\$TOOLBOX_PATH is not set correctly!" >&2
        exit 1
fi


#WORKDIR=$(mktemp -d)
# Mac: http://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
WORKDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
trap 'rm -rf "$WORKDIR"' EXIT
cd $WORKDIR


# model-based T1 reconstruction:

START=$(date +%s)

which bart
bart version

if [ $k_filter -eq 1 ] ; then
	opts="-L -k -i10 -d4 -B0.3 -C300 -s0.475 -R3 -o$overgrid"
else
	opts="-L -i10 -d4 -B0.3 -C300 -s0.475 -R3 -o$overgrid"
fi

echo $k_filter


if [ $sms -eq 1 ]; then
        OMP_NUM_THREADS=10 nice -n10 bart moba $opts -j$lambda -N -t $traj $ksp $TI $reco $sens
else
        OMP_NUM_THREADS=10 nice -n10 bart moba $opts -M -j$lambda -N -t $traj $ksp $TI $reco $sens
fi


END=$(date +%s)
DIFF=$(($END - $START))
echo "It took $DIFF seconds"
