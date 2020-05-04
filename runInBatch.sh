#! /bin/bash


###############################################################################################
source ~/.bash_profile


###############################################################################################
DIR=`dirname $0`

type=''
indir=''
mode='mcmc'
trait_file=$ASR/$mode/species.trait
treefile=''


###############################################################################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--nohup)
			type="nohup"
			;;
		--hpc|--HPC)
			type=hpc
			;;
		--mode)
			mode="$2"
			shift
			;;
		--trait)
			trait_file=$2
			shift
			;;
		--tree|--treefile)
			treefile=$2
			shift
			;;
		*)
			echo "Wrong argu $1" >&2
			exit 1
	esac
	shift
done


if [ -z $type ]; then
	echo "type not given! Exiting ......" >&2
	exit 1
elif [ -z $indir ]; then
	echo "indir not given! Exiting ......" >&2
	exit 1
fi


###############################################################################################
if [ -z $treefile ]; then
	if [ $mode == 'ml' ]; then
		treefile=$ASR/../Rhizo.rooted.no_b.nex
	elif [ $mode == 'mcmc' ]; then
		treefile="$ASR/../Rhizo.ufboot.rooted.nex"
	fi
fi


###############################################################################################
for i in `find $indir -name ${mode}.txt`; do
	#[ -f $i/species.trait ] && continue;
	d=`dirname $i`
	[ ! -f $d/species.trait ] && cp $trait_file $d
	cd $d;
	case $type in
		nohup)
			nohup BayesTraitsV3 $treefile ./species.trait < $mode.txt &
			;;
		hpc)
			submitHPC.sh --cmd "BayesTraitsV3 $treefile ./species.trait < $mode.txt" -n 1 --lsf $mode.lsf --bsub $mode.bsub --df
			;;
		*)
			exit 1
			;;
	esac
	cd -
done


