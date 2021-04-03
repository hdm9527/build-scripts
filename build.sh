#!/bin/bash

# HiiraKernel CI | Powered by Drone | 2020 -

export ARCH=arm64
export PATH="../build-tools/proton-clang/bin:$PATH"
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
export KBUILD_BUILD_USER=apollo
export KBUILD_BUILD_HOST=drone
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"
VERSION="$(cat arch/arm64/configs/vendor/apollo_user_defconfig | grep "CONFIG_LOCALVERSION\=" | sed -r 's/.*"(.+)".*/\1/' | sed 's/^.//')"
git submodule init
git submodule update
echo
echo "Setting defconfig"
echo
make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip vendor/apollo_user_defconfig || exit 1

echo
echo "Compiling"
echo 
make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j${KJOBS} || exit 1

echo
echo "Building Kernel Package"
echo
mkdir kernelzip
mkdir kernelzip/source
cp -rp ../build-tools/anykernel/* kernelzip/
cp arch/arm64/boot/Image.gz kernelzip/source/
cp arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb kernelzip/source/dtb
cd kernelzip
7z a -mx9 $VERSION-tmp.zip *
zipalign -v 4 $VERSION-tmp.zip ../$VERSION.zip
rm $VERSION-tmp.zip
cd ..
ls -al $VERSION.zip && md5sum $VERSION.zip

echo
echo "Uploading"
echo

curl -sL https://git.io/file-transfer | sh
./transfer wet $VERSION.zip
