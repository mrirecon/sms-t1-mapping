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

usage="Usage: $0 [-R TR] [-r res] <reco> <t1map>"

if [ $# -lt 2 ] ; then

        echo "$usage" >&2
        exit 1
fi
while getopts "hR:r:" opt; do
	case $opt in
	h) 
		echo "$usage"
		exit 0 
		;;		
	R) 
		TR=${OPTARG}
		;;
	r) 
		res=${OPTARG}
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))


reco=$(readlink -f "$1")
t1map=$(readlink -f "$2")
TR=$TR
res=$res

if [ ! -e $reco ] ; then
        echo "Input file 'reco' does not exist." >&2
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


t=$(echo $TR 1e-3 | awk '{printf "%4.4f\n",$1*$2}')

bart looklocker -t0.0 -D15.3e-3 $reco map 
bart resize -c 0 $res 1 $res map $t1map



