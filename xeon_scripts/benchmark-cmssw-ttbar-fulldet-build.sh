#! /bin/bash

###########
## Input ##
###########

ben_arch=${1} # SNB, KNL, SKL-SP
suite=${2:-"forPR"} # which set of benchmarks to run: full, forPR, forConf

###################
## Configuration ##
###################

## Source environment and common variables
source xeon_scripts/common-variables.sh ${suite}
source xeon_scripts/init-env.sh

## Platform specific settings
if [[ "${ben_arch}" == "SNB" ]]
then
    mOpt="-j 12"
    dir=/data2/nfsmic/slava77/samples
    maxth=24
    maxvu=8
    declare -a nths=("1" "2" "4" "6" "8" "12" "16" "20" "24")
    declare -a nvus=("1" "2" "4" "8")
    declare -a nevs=("1" "2" "4" "8" "12")
elif [[ "${ben_arch}" == "KNL" ]]
then
    mOpt="-j 64 AVX_512:=1"
    dir=/data1/work/slava77/samples
    maxth=256
    maxvu=16
    declare -a nths=("1" "2" "4" "8" "16" "32" "64" "96" "128" "160" "192" "224" "256")
    declare -a nvus=("1" "2" "4" "8" "16")
    declare -a nevs=("1" "2" "4" "8" "16" "32" "64" "128")
elif [[ "${ben_arch}" == "SKL-SP" ]]
then
    mOpt="-j 32 AVX_512:=1"
    dir=/data2/slava77/samples
    maxth=64
    maxvu=16
    declare -a nths=("1" "2" "4" "8" "16" "32" "48" "64")
    declare -a nvus=("1" "2" "4" "8" "16")
    declare -a nevs=("1" "2" "4" "8" "16" "32" "64")
else 
    echo ${ben_arch} "is not a valid architecture! Exiting..."
    exit
fi

## Common file setup
subdir=2017/pass-c93773a/initialStep/PU70HS/10224.0_TTbar_13+TTbar_13TeV_TuneCUETP8M1_2017PU_GenSimFullINPUT+DigiFullPU_2017PU+RecoFullPU_2017PU+HARVESTFullPU_2017PU
file=memoryFile.fv3.clean.writeAll.CCC1620.recT.082418-25daeda.bin
nevents=20

## Common executable setup
minth=1
minvu=1
seeds="--cmssw-n2seeds"
exe="./mkFit/mkFit ${seeds} --input-file ${dir}/${subdir}/${file}"

## Common output setup
dump=DumpForPlots
base=${ben_arch}_${sample}

####################
## Run Benchmarks ##
####################

## compile with appropriate options
make distclean ${mOpt}
make ${mOpt}

## Parallelization Benchmarks
for nth in "${nths[@]}"
do
    for build in "${th_builds[@]}"
    do echo ${!build} | while read -r bN bO
	do
	    ## Base executable
	    oBase=${base}_${bN}
	    bExe="${exe} --build-${bO} --num-thr ${nth}"

	    ## Building-only benchmark
	    echo "${oBase}: Benchmark [nTH:${nth}, nVU:${maxvu}int]"
	    ${bExe} --num-events ${nevents} >& log_${oBase}_NVU${maxvu}int_NTH${nth}.txt

	    ## Multiple Events in Flight benchmark
	    check_meif=$( CheckIfMEIF ${build} )
	    if [[ "${check_meif}" == "true" ]]
	    then
		for nev in "${nevs[@]}"
		do
		    if (( ${nev} <= ${nth} ))
		    then
			nproc=$(( ${nevents} * ${nev} ))
			echo "${oBase}: Benchmark [nTH:${nth}, nVU:${maxvu}int, nEV:${nev}]"
			${bExe} --silent --num-thr-ev ${nev} --num-events ${nproc} >& log_${oBase}_NVU${maxvu}int_NTH${nth}_NEV${nev}.txt
		    fi
		done
	    fi

	    ## nHits validation
	    check_text=$( CheckIfText ${build} )
	    if (( ${nth} == ${maxth} )) && [[ "${check_text}" == "true" ]]
	    then
		echo "${oBase}: Text dump for plots [nTH:${nth}, nVU:${maxvu}int]"
		${bExe} --dump-for-plots --quality-val --read-cmssw-tracks --num-events ${nevents} >& log_${oBase}_NVU${maxvu}int_NTH${nth}_${dump}.txt
	    fi
	done
    done
done

## Final cleanup
make distclean ${mOpt}

## Final message
echo "Finished compute benchmarks on ${ben_arch}!"
