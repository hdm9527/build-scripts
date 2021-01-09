#!/bin/bash

# IceKernel CI | Powered by Drone | 2020 -

export ARCH=arm64
export CROSS_COMPILE=../build-tools/arm64-gcc/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=../build-tools/arm32-gcc/bin/arm-eabi-
export KBUILD_BUILD_USER=misaka
export KBUILD_BUILD_HOST=tp-workstation
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"
VERSION="$(cat arch/arm64/configs/sm8150-perf_defconfig | grep "CONFIG_LOCALVERSION\=" | sed -r 's/.*"(.+)".*/\1/' | sed 's/^.//')"

echo
echo "Setting defconfig"
echo
make sm8150-perf_defconfig || exit 1

echo
echo "Compiling"
echo 
make -j${KJOBS} || exit 1

echo
echo "Building Kernel Package"
echo
mkdir kernelzip
mkdir kernelzip/source
cp -rp ../build-tools/anykernel/* kernelzip/
cp arch/arm64/boot/Image.gz kernelzip/source/
find arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > kernelzip/source/dtb
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
