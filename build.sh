#!/bin/bash

export ARCH=arm64
export LLVM=1
export LLVM_IAS=1
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
export PATH="${HOME}/build-tools/proton-clang/bin:$PATH"
export KBUILD_BUILD_USER=apollo
export KBUILD_BUILD_HOST=drone
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"
VERSION="latekernel-$(date '+%Y-%m%d-%H%M')"

echo
echo "Setting defconfig"
echo
if [ -f arch/arm64/configs/vendor/apollo_defconfig ]
then
    make CC=clang LLVM=1 LLVM_IAS=1 vendor/apollo_defconfig
else
    make CC=clang LLVM=1 LLVM_IAS=1 lateapollo_defconfig
fi

echo
echo "Compiling"
echo 
make CC=clang LLVM=1 LLVM_IAS=1 -j${KJOBS}

echo
echo "Building Kernel Package"

echo
sudo mkdir kernelzip
sudo mkdir kernelzip/source
sudo cp -rp ../anykernel/* kernelzip/
sudo cp arch/arm64/boot/Image kernelzip/source/
sudo cp arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb kernelzip/source/dtb
cd kernelzip
7z a -mx9 $VERSION-tmp.zip *
zipalign -v 4 $VERSION-tmp.zip ../$VERSION.zip
sudo rm $VERSION-tmp.zip
cd ..
ls -al $VERSION.zip && md5sum $VERSION.zip

