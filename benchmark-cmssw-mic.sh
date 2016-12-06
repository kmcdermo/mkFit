#! /bin/bash

dir=/nfsmic/cerati/

patch < cmssw-config.patch

make -j 8

for nth in 1 3 7 21 42 63 84 105 126 147 168 189 210
do
echo "mic cmssw" nth=${nth} "STD"
ssh mic0 ./mkFit-mic --read --file-name ${dir}/cmssw_100xTTbarPU35_polar_split_mock_noFWD.bin --cms-geom --cmssw-seeds --build-std --num-thr ${nth} >& log_mic_100xTTbarPU35_STD_NVU16int_NTH${nth}.txt
done

sed -i 's/# USE_INTRINSICS := -DMPT_SIZE=1/USE_INTRINSICS := -DMPT_SIZE=XX/g' Makefile.config
for nvu in 1 2 4 8 16
do
sed -i "s/MPT_SIZE=XX/MPT_SIZE=${nvu}/g" Makefile.config
make clean
make -j 8
echo "mic cmssw" nvu=${nvu} "STD"
ssh mic0 ./mkFit-mic --read --file-name ${dir}/cmssw_100xTTbarPU35_polar_split_mock_noFWD.bin --cms-geom --cmssw-seeds --build-std --num-thr 1 >& log_mic_100xTTbarPU35_STD_NVU${nvu}_NTH1.txt
sed -i "s/MPT_SIZE=${nvu}/MPT_SIZE=XX/g" Makefile.config
done
sed -i 's/USE_INTRINSICS := -DMPT_SIZE=XX/# USE_INTRINSICS := -DMPT_SIZE=1/g' Makefile.config

patch -R < cmssw-config.patch

make clean
make -j 8
